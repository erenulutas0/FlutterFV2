package com.ingilizce.calismaapp.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.io.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Base64;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.List;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

@Service
public class PiperTtsService {
    private static final Logger log = LoggerFactory.getLogger(PiperTtsService.class);

    @Value("${piper.tts.path:}")
    private String configuredPiperPath;

    @Value("${piper.tts.default-model:en_US-amy-medium.onnx}")
    private String configuredDefaultModel;

    // --- KRİTİK DEĞİŞİKLİK BURADA ---
    // Modelleri Türkçe karakter sorunu olmaması için C:\piper klasöründen okuyoruz.
    // Docker'da /piper mount point'i kullanılır
    private static final String MODEL_BASE_DIR = System.getProperty("os.name").toLowerCase().contains("windows")
            ? "C:\\piper"
            : "/piper";

    // Modellerin dosya isimleri (C:\piper klasöründe olmalı)
    private static final String MODEL_LESSAC = "en_US-lessac-medium.onnx";
    private static final String MODEL_AMY = "en_US-amy-medium.onnx";
    private static final String MODEL_ALAN = "en_GB-alan-medium.onnx";
    // Yeni eklenen modeller
    private static final String MODEL_RYAN = "en_US-ryan-medium.onnx";
    private static final String MODEL_JENNY = "en_GB-jenny_dioco-medium.onnx";
    private static final String MODEL_CORI = "en_GB-cori-medium.onnx";

    /**
     * Generate speech audio from text using Piper TTS
     * 
     * @param text  Text to convert to speech
     * @param voice Voice model to use (lessac, amy, alan, ryan, etc.)
     * @return Base64 encoded WAV audio data
     */
    public String synthesizeSpeech(String text, String voice) {
        try {
            // Select model based on voice
            String modelFile = getModelFile(voice);

            // Create temporary output file
            Path outputPath = createTempOutputPath();
            String outputFile = outputPath.toString();

            // Build Piper command - use absolute path for model file
            File modelFileObj = new File(modelFile);
            String absoluteModelPath = modelFileObj.getAbsolutePath();

            // Verify model file exists
            if (!pathExists(absoluteModelPath)) {
                throw new RuntimeException("Model file not found at SAFE path: " + absoluteModelPath);
            }
            log.debug("Using SAFE model file: {}", absoluteModelPath);
            log.debug("Model file exists: {}", pathExists(absoluteModelPath));

            String piperPath = findPiperPath();
            log.debug("Using Piper path: {}", piperPath);

            // Working directory setup moved here
            File workingDir = new File(MODEL_BASE_DIR);

            List<String> command = new ArrayList<>();
            command.add(piperPath);
            command.add("--model");
            command.add(absoluteModelPath);
            command.add("--output_file");
            command.add(outputFile);

            Process process = startProcess(command, workingDir);

            // Write text to process stdin and explicitly close it
            OutputStream stdin = process.getOutputStream();
            try (BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(stdin, java.nio.charset.StandardCharsets.UTF_8))) {
                writer.write(text);
                writer.flush();
            } finally {
                // Explicitly close stdin to signal end of input
                try {
                    stdin.close();
                } catch (IOException e) {
                    log.warn("Error closing Piper stdin", e);
                }
            }

            // Read output/error stream in a separate thread to prevent blocking
            StringBuilder output = new StringBuilder();
            final Process finalProcess = process;

            Thread outputThread = new Thread(() -> {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(finalProcess.getInputStream(),
                                java.nio.charset.StandardCharsets.UTF_8))) {
                    String line;
                    while ((line = reader.readLine()) != null) {
                        output.append(line).append("\n");
                        log.debug("Piper output: {}", line);
                    }
                } catch (IOException e) {
                    log.warn("Error reading Piper output", e);
                }
            });
            outputThread.setDaemon(true);
            outputThread.start();

            // Wait for process to complete with timeout (30 seconds)
            boolean finished = process.waitFor(30, TimeUnit.SECONDS);
            if (!finished) {
                process.destroyForcibly();
                throw new RuntimeException("Piper TTS process timed out after 30 seconds");
            }

            outputThread.join(5000); // Wait max 5 seconds for output thread

            int exitCode = process.exitValue();

            if (exitCode != 0) {
                String errorMsg = output.length() > 0 ? output.toString()
                        : "Unknown error (exit code: " + exitCode + ")";
                log.error("Piper TTS failed with exit code={}", exitCode);
                log.error("Piper output: {}", errorMsg);
                throw new RuntimeException("Piper TTS failed: " + errorMsg);
            }

            // Read generated audio file
            byte[] audioData = readAllBytes(outputPath);

            // Clean up temporary file
            deleteIfExists(outputPath);

            // Return base64 encoded audio
            return Base64.getEncoder().encodeToString(audioData);

        } catch (Exception e) {
            throw new RuntimeException("Failed to synthesize speech: " + e.getMessage(), e);
        }
    }

    /**
     * Get model file path based on voice name
     */
    protected String getModelFile(String voice) {
        String normalizedVoice = normalizeVoice(voice);
        Map<String, String> voiceModels = getVoiceModelMap();

        String requestedModel = voiceModels.getOrDefault(normalizedVoice, getDefaultModelName());
        String requestedPath = getModelBaseDir() + File.separator + requestedModel;
        if (pathExists(requestedPath)) {
            log.debug("Selected model path (SAFE): {}", requestedPath);
            return requestedPath;
        }

        if (!voiceModels.containsKey(normalizedVoice)) {
            log.warn("Unknown voice requested: {}, falling back to default model", voice);
        } else {
            log.warn("Requested voice model not found: {}", requestedPath);
        }

        String defaultPath = getModelBaseDir() + File.separator + getDefaultModelName();
        if (pathExists(defaultPath)) {
            log.info("Falling back to configured default model: {}", defaultPath);
            return defaultPath;
        }

        String firstAvailable = resolveFirstAvailableModelPath();
        if (firstAvailable != null) {
            log.info("Falling back to first available model: {}", firstAvailable);
            return firstAvailable;
        }

        // Let caller fail with explicit model-not-found message.
        log.warn("No Piper model file found under {}", getModelBaseDir());
        return defaultPath;
    }

    /**
     * Find Piper executable path
     */
    protected String findPiperPath() {
        // First, try configured path
        if (configuredPiperPath != null && !configuredPiperPath.trim().isEmpty()) {
            String path = configuredPiperPath.trim();

            if (pathExists(path)) {
                return absolutePath(path);
            }
        }

        // Try common locations (including our new safe location)
        // Docker'da Linux path'leri, Windows'ta Windows path'leri
        boolean isWindows = isWindows();
        String[] pathsToTry = isWindows ? new String[] {
                "C:\\piper\\piper.exe", // Windows location
                "piper.exe",
                "piper"
        }
                : new String[] {
                        "/usr/local/bin/piper", // Docker installed location
                        "/piper/piper", // Docker mount location (fallback)
                        "piper"
                };

        for (String path : pathsToTry) {
            if (pathExists(path) && pathCanExecute(path)) {
                return absolutePath(path);
            }
            // Check if it's just a command available in PATH
            if (!path.contains(File.separator) && !path.contains("/") && !path.contains("\\")) {
                return path;
            }
        }

        return "piper";
    }

    /**
     * Check if Piper TTS is available
     */
    public boolean isAvailable() {
        try {
            String piperPath = findPiperPath();
            log.debug("Trying Piper path: {}", piperPath);

            Process process = startAvailabilityProcess(piperPath);

            long startTime = System.currentTimeMillis();
            while (process.isAlive() && (System.currentTimeMillis() - startTime) < 5000) {
                Thread.sleep(100);
            }

            if (process.isAlive()) {
                process.destroy();
                return false;
            }

            int exitCode = process.exitValue();

            String modelPath = resolveFirstAvailableModelPath();
            boolean modelExists = modelPath != null;

            log.debug("Piper TTS check - path: {}, exitCode: {}, modelPath: {}", piperPath, exitCode, modelPath);

            return exitCode == 0 && modelExists;
        } catch (Exception e) {
            log.warn("Piper TTS availability check failed", e);
            return false;
        }
    }

    public String[] getSupportedVoices() {
        Map<String, String> voiceModels = getVoiceModelMap();
        Set<String> supported = new LinkedHashSet<>();

        String defaultPath = getModelBaseDir() + File.separator + getDefaultModelName();
        if (pathExists(defaultPath)) {
            supported.add("default");
        }

        for (Map.Entry<String, String> entry : voiceModels.entrySet()) {
            String voice = entry.getKey();
            if ("default".equals(voice)) {
                continue;
            }

            String modelPath = getModelBaseDir() + File.separator + entry.getValue();
            if (pathExists(modelPath)) {
                supported.add(voice);
            }
        }

        return supported.toArray(new String[0]);
    }

    private String normalizeVoice(String voice) {
        if (voice == null || voice.trim().isEmpty()) {
            return "default";
        }
        String normalized = voice.trim().toLowerCase();
        if ("jenny_dioco".equals(normalized)) {
            return "jenny";
        }
        return normalized;
    }

    private String getDefaultModelName() {
        if (configuredDefaultModel == null || configuredDefaultModel.trim().isEmpty()) {
            return MODEL_AMY;
        }
        return configuredDefaultModel.trim();
    }

    private Map<String, String> getVoiceModelMap() {
        Map<String, String> voiceModels = new LinkedHashMap<>();
        voiceModels.put("default", getDefaultModelName());
        voiceModels.put("amy", MODEL_AMY);
        voiceModels.put("alan", MODEL_ALAN);
        voiceModels.put("lessac", MODEL_LESSAC);
        voiceModels.put("ryan", MODEL_RYAN);
        voiceModels.put("jenny", MODEL_JENNY);
        voiceModels.put("cori", MODEL_CORI);
        return voiceModels;
    }

    private String resolveFirstAvailableModelPath() {
        Set<String> modelNames = new LinkedHashSet<>(getVoiceModelMap().values());
        for (String modelName : modelNames) {
            String modelPath = getModelBaseDir() + File.separator + modelName;
            if (pathExists(modelPath)) {
                return modelPath;
            }
        }
        return null;
    }

    /**
     * Start the process. Protected to allow mocking in tests.
     */
    protected Process startProcess(List<String> command, File workingDir) throws IOException {
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        if (workingDir != null && workingDir.exists()) {
            processBuilder.directory(workingDir);
        }
        processBuilder.redirectErrorStream(true);
        return processBuilder.start();
    }

    protected Process startAvailabilityProcess(String piperPath) throws IOException {
        ProcessBuilder processBuilder = new ProcessBuilder(piperPath, "--version");
        processBuilder.redirectErrorStream(true);
        return processBuilder.start();
    }

    protected boolean pathExists(String path) {
        return new File(path).exists();
    }

    protected boolean pathCanExecute(String path) {
        return new File(path).canExecute();
    }

    protected String absolutePath(String path) {
        return new File(path).getAbsolutePath();
    }

    protected Path createTempOutputPath() {
        String tempDir = System.getProperty("java.io.tmpdir");
        return Paths.get(tempDir, UUID.randomUUID() + ".wav");
    }

    protected byte[] readAllBytes(Path path) throws IOException {
        return Files.readAllBytes(path);
    }

    protected void deleteIfExists(Path path) throws IOException {
        Files.deleteIfExists(path);
    }

    protected String getModelBaseDir() {
        return MODEL_BASE_DIR;
    }

    protected boolean isWindows() {
        return System.getProperty("os.name").toLowerCase().contains("windows");
    }
}
