package com.ingilizce.calismaapp.controller;

import com.corundumstudio.socketio.SocketIOClient;
import com.corundumstudio.socketio.SocketIOServer;
import com.ingilizce.calismaapp.service.MatchmakingService;
import com.ingilizce.calismaapp.service.MatchmakingService.MatchInfo;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
@ConditionalOnProperty(name = { "app.features.community.enabled", "app.socketio.enabled" }, havingValue = "true", matchIfMissing = false)
public class MatchmakingController {
    private static final Logger log = LoggerFactory.getLogger(MatchmakingController.class);

    @Autowired
    private SocketIOServer socketIOServer;

    @Autowired
    private MatchmakingService matchmakingService;

    // userId -> client mapping
    private final Map<String, SocketIOClient> userIdToClient = new ConcurrentHashMap<>();

    @PostConstruct
    public void startSocketIOServer() {
        // Event listener'ları manuel olarak ekle
        socketIOServer.addConnectListener(client -> {
            log.info("Client connected: sessionId={}, remoteAddress={}", client.getSessionId(), client.getRemoteAddress());
        });

        socketIOServer.addDisconnectListener(client -> {
            String userId = client.get("userId");
            if (userId != null) {
                log.info("Client disconnected: userId={}", userId);

                // Eğer aktif bir eşleşme varsa, diğer kullanıcıya bildir
                MatchInfo match = matchmakingService.getMatch(userId);
                if (match != null) {
                    String matchedUserId = match.user1.equals(userId) ? match.user2 : match.user1;
                    SocketIOClient matchedClient = userIdToClient.get(matchedUserId);
                    if (matchedClient != null) {
                        // Room'dan çıkar
                        matchedClient.leaveRoom(match.roomId);
                        // call_ended event'i gönder
                        matchedClient.sendEvent("call_ended");
                        log.info("Sent call_ended to matched userId={} in roomId={}", matchedUserId, match.roomId);
                    }
                    // Eşleşmeyi sonlandır
                    matchmakingService.endMatch(userId);
                }

                matchmakingService.leaveQueue(userId);
                userIdToClient.remove(userId); // Client'ı map'ten kaldır
            } else {
                log.info("Client disconnected: sessionId={} (userId not set)", client.getSessionId());
            }
        });

        // join_queue event listener
        socketIOServer.addEventListener("join_queue", Map.class, (client, data, ackRequest) -> {
            log.info("join_queue event received: sessionId={}, payload={}", client.getSessionId(), data);

            String userId = null;
            if (data.get("userId") != null) {
                userId = data.get("userId").toString();
            }

            if (userId == null || userId.isBlank()) {
                Map<String, Object> error = new HashMap<>();
                error.put("status", "error");
                error.put("error", "userId is required");
                client.sendEvent("queue_error", error);
                log.warn("Rejected join_queue: missing userId for sessionId={}", client.getSessionId());
                return;
            }

            log.info("join_queue accepted: userId={}", userId);

            client.set("userId", userId);
            userIdToClient.put(userId, client); // Client mapping'i ekle

            MatchInfo match = matchmakingService.joinQueue(userId);

            log.info("Match result={}, queueSize={}", match != null ? "FOUND" : "WAITING", matchmakingService.getQueueSize());

            Map<String, Object> response = new HashMap<>();

            if (match != null) {
                // Eşleşme bulundu!
                log.info("Match found: roomId={}", match.roomId);
                String matchedUserId = match.user1.equals(userId) ? match.user2 : match.user1;

                // Rolleri belirle: user1 caller (arayan), user2 callee (aranan)
                // user1 (kuyrukta bekleyen) caller olur, user2 (yeni gelen) callee olur
                String callerUserId = match.user1; // İlk kuyruğa giren
                String calleeUserId = match.user2; // İkinci gelen

                // Caller'a (user1) bildir
                Map<String, Object> response1 = new HashMap<>();
                response1.put("status", "matched");
                response1.put("roomId", match.roomId);
                response1.put("matchedUserId", matchedUserId);
                String role1 = callerUserId.equals(userId) ? "caller" : "callee";
                response1.put("role", role1);
                log.debug("match_found payload for userId={}: {}", userId, response1);
                client.sendEvent("match_found", response1);
                log.info("Sent match_found event: userId={}, role={}, roomId={}", userId, role1, match.roomId);

                // Callee'ye (user2) bildir
                SocketIOClient matchedClient = userIdToClient.get(matchedUserId);
                if (matchedClient != null) {
                    Map<String, Object> response2 = new HashMap<>();
                    response2.put("status", "matched");
                    response2.put("roomId", match.roomId);
                    response2.put("matchedUserId", userId);
                    String role2 = calleeUserId.equals(matchedUserId) ? "callee" : "caller";
                    response2.put("role", role2);
                    log.debug("match_found payload for matchedUserId={}: {}", matchedUserId, response2);
                    matchedClient.sendEvent("match_found", response2);
                    log.info("Sent match_found event: matchedUserId={}, role={}, roomId={}", matchedUserId, role2, match.roomId);
                } else {
                    log.warn("Matched client not found for userId={}", matchedUserId);
                }
            } else {
                // Kuyrukta bekliyor
                response.put("status", "waiting");
                response.put("queueSize", matchmakingService.getQueueSize());
                client.sendEvent("queue_status", response);
                log.info("Sent queue_status event: userId={}, queueSize={}", userId, matchmakingService.getQueueSize());
            }
        });

        // leave_queue event listener
        socketIOServer.addEventListener("leave_queue", String.class, (client, data, ackRequest) -> {
            String userId = client.get("userId");
            if (userId != null) {
                matchmakingService.leaveQueue(userId);
            }
        });

        // join_room event listener
        socketIOServer.addEventListener("join_room", Map.class, (client, data, ackRequest) -> {
            String roomId = (String) data.get("roomId");
            String userId = client.get("userId");

            if (roomId != null && userId != null) {
                client.joinRoom(roomId);
                log.info("User joined room: userId={}, roomId={}", userId, roomId);
            }
        });

        // WebRTC offer event listener
        socketIOServer.addEventListener("webrtc_offer", Map.class, (client, data, ackRequest) -> {
            log.info("WebRTC offer event received: payloadType={}", data != null ? data.getClass().getName() : "null");

            String roomId = (String) data.get("roomId");
            String userId = client.get("userId");

            log.info("WebRTC offer received: userId={}, roomId={}", userId, roomId);

            Object offerObj = data.get("offer");
            log.debug("WebRTC offer type={}", offerObj != null ? offerObj.getClass().getName() : "null");

            // Offer'ı diğer kullanıcıya ilet
            Map<String, Object> offerData = new HashMap<>();
            offerData.put("offer", offerObj);
            offerData.put("from", userId);

            log.debug("Forwarding WebRTC offer to roomId={}", roomId);
            socketIOServer.getRoomOperations(roomId).sendEvent("webrtc_offer", offerData);
            log.info("WebRTC offer forwarded to roomId={}", roomId);
        });

        // WebRTC answer event listener
        socketIOServer.addEventListener("webrtc_answer", Map.class, (client, data, ackRequest) -> {
            log.info("WebRTC answer event received: payload={}", data);

            String roomId = (String) data.get("roomId");
            String userId = client.get("userId");

            log.info("WebRTC answer received: userId={}, roomId={}", userId, roomId);

            Object answerObj = data.get("answer");
            log.debug("WebRTC answer type={}", answerObj != null ? answerObj.getClass().getName() : "null");

            // Answer'ı diğer kullanıcıya ilet
            Map<String, Object> answerData = new HashMap<>();
            answerData.put("answer", answerObj);
            answerData.put("from", userId);

            log.debug("Forwarding WebRTC answer to roomId={}", roomId);
            socketIOServer.getRoomOperations(roomId).sendEvent("webrtc_answer", answerData);
            log.info("WebRTC answer forwarded to roomId={}", roomId);
        });

        // WebRTC ICE candidate event listener
        socketIOServer.addEventListener("webrtc_ice_candidate", Map.class, (client, data, ackRequest) -> {
            String roomId = (String) data.get("roomId");
            String userId = client.get("userId");

            // ICE candidate verilerini eksiksiz al
            Object candidateStr = data.get("candidate");
            Object sdpMid = data.get("sdpMid");
            Object sdpMLineIndex = data.get("sdpMLineIndex");

            // ICE candidate'ı diğer kullanıcıya ilet
            Map<String, Object> candidateData = new HashMap<>();
            candidateData.put("candidate", candidateStr);
            candidateData.put("sdpMid", sdpMid);
            candidateData.put("sdpMLineIndex", sdpMLineIndex);
            candidateData.put("from", userId);

            socketIOServer.getRoomOperations(roomId).sendEvent("webrtc_ice_candidate", candidateData);
        });

        // end_call event listener
        socketIOServer.addEventListener("end_call", Map.class, (client, data, ackRequest) -> {
            String roomId = (String) data.get("roomId");
            String userId = client.get("userId");

            if (userId != null) {
                matchmakingService.endMatch(userId);

                // Diğer kullanıcıya bildir
                socketIOServer.getRoomOperations(roomId).sendEvent("call_ended");
                log.info("Call ended by userId={} in roomId={}", userId, roomId);
            }
        });

        try {
            socketIOServer.start();
            log.info("Socket.IO server started on port 9092");
        } catch (Exception e) {
            log.error("Failed to start Socket.IO server", e);
        }
    }

    @PreDestroy
    public void stopSocketIOServer() {
        socketIOServer.stop();
    }

    // Tüm event listener'lar PostConstruct'ta manuel olarak ekleniyor
}
