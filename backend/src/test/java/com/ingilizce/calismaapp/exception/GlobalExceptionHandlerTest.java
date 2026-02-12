package com.ingilizce.calismaapp.exception;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.ConstraintViolationException;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;

import java.util.NoSuchElementException;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    @Test
    void handleBadRequest_ShouldUseExceptionMessageForIllegalArgument() {
        HttpServletRequest request = mockRequest("POST", "/api/test");

        ResponseEntity<ApiErrorResponse> response =
                handler.handleBadRequest(new IllegalArgumentException("bad input"), request);

        assertEquals(400, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("bad input", response.getBody().message());
        assertEquals("/api/test", response.getBody().path());
    }

    @Test
    void handleBadRequest_ShouldFormatMissingParameterMessage() {
        HttpServletRequest request = mockRequest("GET", "/api/search");
        MissingServletRequestParameterException ex =
                new MissingServletRequestParameterException("q", "String");

        ResponseEntity<ApiErrorResponse> response = handler.handleBadRequest(ex, request);

        assertEquals(400, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("Missing required parameter: q", response.getBody().message());
    }

    @Test
    void handleBadRequest_ShouldUseConstraintViolationMessage() {
        HttpServletRequest request = mockRequest("POST", "/api/validate");
        ConstraintViolation<?> violation = mock(ConstraintViolation.class);
        when(violation.getMessage()).thenReturn("must not be blank");
        ConstraintViolationException ex = new ConstraintViolationException("validation failed", Set.of(violation));

        ResponseEntity<ApiErrorResponse> response = handler.handleBadRequest(ex, request);

        assertEquals(400, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("must not be blank", response.getBody().message());
    }

    @Test
    void handleBadRequest_ShouldUseFieldErrorMessageForValidationException() {
        HttpServletRequest request = mockRequest("POST", "/api/words");
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult bindingResult = mock(BindingResult.class);
        FieldError fieldError = new FieldError("createWordRequest", "englishWord", "englishWord is required");

        when(ex.getBindingResult()).thenReturn(bindingResult);
        when(bindingResult.getFieldError()).thenReturn(fieldError);

        ResponseEntity<ApiErrorResponse> response = handler.handleBadRequest(ex, request);

        assertEquals(400, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("englishWord is required", response.getBody().message());
    }

    @Test
    void handleBadRequest_ShouldFallbackToInvalidRequestMessageWhenExceptionMessageIsNull() {
        HttpServletRequest request = mockRequest("POST", "/api/test");

        ResponseEntity<ApiErrorResponse> response =
                handler.handleBadRequest(new IllegalArgumentException(), request);

        assertEquals(400, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("Invalid request", response.getBody().message());
    }

    @Test
    void handleConflict_ShouldReturnConflictStatusAndGenericMessage() {
        HttpServletRequest request = mockRequest("POST", "/api/users");

        ResponseEntity<ApiErrorResponse> response =
                handler.handleConflict(new DataIntegrityViolationException("duplicate key"), request);

        assertEquals(409, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("Request conflicts with current data state", response.getBody().message());
    }

    @Test
    void handleNotFound_ShouldFallbackMessageWhenNull() {
        HttpServletRequest request = mockRequest("GET", "/api/missing");

        ResponseEntity<ApiErrorResponse> response =
                handler.handleNotFound(new NoSuchElementException(), request);

        assertEquals(404, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("Resource not found", response.getBody().message());
    }

    @Test
    void handleUnexpected_ShouldHideInternalDetails() {
        HttpServletRequest request = mockRequest("PUT", "/api/internal");

        ResponseEntity<ApiErrorResponse> response =
                handler.handleUnexpected(new RuntimeException("sensitive"), request);

        assertEquals(500, response.getStatusCode().value());
        assertNotNull(response.getBody());
        assertEquals("Internal server error", response.getBody().message());
        assertEquals("/api/internal", response.getBody().path());
    }

    private HttpServletRequest mockRequest(String method, String uri) {
        HttpServletRequest request = mock(HttpServletRequest.class);
        when(request.getMethod()).thenReturn(method);
        when(request.getRequestURI()).thenReturn(uri);
        return request;
    }
}
