package com.citizenscience.security;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for JwtUtil.
 * Verifies token generation, claim extraction, and validation logic.
 */
class JwtUtilTest {

    // 64-character secret → 512 bits, well above the HMAC-SHA256 minimum of 256 bits
    private static final String TEST_SECRET =
            "testSecretKeyForJwtUnitTestsThatIsAtLeast256BitsLongForHmacSha256";
    private static final long EXPIRATION_MS = 86_400_000L; // 24 h
    private static final String TEST_EMAIL = "user@example.com";

    private JwtUtil jwtUtil;

    @BeforeEach
    void setUp() {
        jwtUtil = new JwtUtil();
        ReflectionTestUtils.setField(jwtUtil, "secret", TEST_SECRET);
        ReflectionTestUtils.setField(jwtUtil, "expiration", EXPIRATION_MS);
    }

    // ── generateToken ────────────────────────────────────────────────────────

    @Test
    void givenValidEmail_whenGenerateToken_thenReturnsNonBlankToken() {
        // Act
        String token = jwtUtil.generateToken(TEST_EMAIL);

        // Assert
        assertThat(token).isNotBlank();
    }

    @Test
    void givenSameEmail_whenGenerateTokenTwice_thenBothTokensAreValid() {
        // Act
        String token1 = jwtUtil.generateToken(TEST_EMAIL);
        String token2 = jwtUtil.generateToken(TEST_EMAIL);

        // Assert – both tokens must be non-blank and valid for the same email
        assertThat(token1).isNotBlank();
        assertThat(token2).isNotBlank();
        assertThat(jwtUtil.validateToken(token1, TEST_EMAIL)).isTrue();
        assertThat(jwtUtil.validateToken(token2, TEST_EMAIL)).isTrue();
    }

    // ── extractEmail ─────────────────────────────────────────────────────────

    @Test
    void givenGeneratedToken_whenExtractEmail_thenReturnsOriginalEmail() {
        // Arrange
        String token = jwtUtil.generateToken(TEST_EMAIL);

        // Act
        String extracted = jwtUtil.extractEmail(token);

        // Assert
        assertThat(extracted).isEqualTo(TEST_EMAIL);
    }

    @Test
    void givenMalformedToken_whenExtractEmail_thenThrowsException() {
        // Arrange
        String badToken = "not.a.valid.jwt";

        // Act & Assert
        assertThatThrownBy(() -> jwtUtil.extractEmail(badToken))
                .isInstanceOf(Exception.class);
    }

    // ── validateToken ────────────────────────────────────────────────────────

    @Test
    void givenValidToken_whenValidateToken_thenReturnsTrue() {
        // Arrange
        String token = jwtUtil.generateToken(TEST_EMAIL);

        // Act
        Boolean valid = jwtUtil.validateToken(token, TEST_EMAIL);

        // Assert
        assertThat(valid).isTrue();
    }

    @Test
    void givenValidToken_whenValidateTokenWithWrongEmail_thenReturnsFalse() {
        // Arrange
        String token = jwtUtil.generateToken(TEST_EMAIL);

        // Act
        Boolean valid = jwtUtil.validateToken(token, "other@example.com");

        // Assert
        assertThat(valid).isFalse();
    }

    @Test
    void givenExpiredToken_whenValidateToken_thenThrowsException() {
        // Arrange – use a 1-ms expiration so the token expires immediately
        JwtUtil shortLivedUtil = new JwtUtil();
        ReflectionTestUtils.setField(shortLivedUtil, "secret", TEST_SECRET);
        ReflectionTestUtils.setField(shortLivedUtil, "expiration", 1L);

        String expiredToken = shortLivedUtil.generateToken(TEST_EMAIL);

        // Act & Assert – JJWT throws when the token is expired
        assertThatThrownBy(() -> shortLivedUtil.validateToken(expiredToken, TEST_EMAIL))
                .isInstanceOf(Exception.class);
    }

    // ── extractExpiration ────────────────────────────────────────────────────

    @Test
    void givenGeneratedToken_whenExtractExpiration_thenExpirationIsInTheFuture() {
        // Arrange
        String token = jwtUtil.generateToken(TEST_EMAIL);

        // Act
        java.util.Date expiration = jwtUtil.extractExpiration(token);

        // Assert
        assertThat(expiration).isAfter(new java.util.Date());
    }
}
