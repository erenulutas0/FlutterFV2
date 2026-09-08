package com.ingilizce.calismaapp.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * The seed rows and the migration that corrects them must agree.
 *
 * <p>Flyway runs before the CommandLineRunner in DataLoader, so on an EMPTY database
 * V030's UPDATE statements match no rows and whatever DataLoader inserts is what that
 * environment ships with. The two had drifted: V030 set PRO_ANNUAL to 1199.99 for a
 * product Google sells at 1199.99, while DataLoader seeded 999.99 — the exact price bug
 * V030 exists to fix, waiting to come back on the next fresh database, staging
 * environment or restored backup, with the paywall quoting a price nobody is charged.
 *
 * <p>Compared as text rather than by booting the context, because the failure this
 * guards is someone editing one file and not the other, and text is what they edit.
 */
class SeedPlansMatchMigrationTest {

    private static String read(Path path) throws IOException {
        assertTrue(Files.exists(path), "missing " + path);
        return Files.readString(path, StandardCharsets.UTF_8);
    }

    @Test
    @DisplayName("a fresh database is seeded with the prices the store actually charges")
    void seededPricesMatchTheMigration() throws IOException {
        String seed = read(Path.of("src", "main", "java", "com", "ingilizce",
                "calismaapp", "config", "DataLoader.java"));
        String migration = read(Path.of("src", "main", "resources", "db", "migration",
                "V030__align_plan_quota_metadata_with_enforcement.sql"));

        // The annual plan: the one that drifted, and the one with real money on it.
        assertTrue(migration.contains("price = 1199.99"),
                "V030 no longer sets the annual price; this test is out of date");
        assertTrue(seed.contains("new BigDecimal(\"1199.99\")"),
                "DataLoader would seed a fresh database with a stale annual price");

        // The quota text each plan advertises, which V030 exists to keep honest.
        assertTrue(seed.contains("Base app access with 8k daily AI token quota."),
                "the free plan's seeded description disagrees with V030");
        assertTrue(seed.contains("AI access with 100k daily token quota."),
                "the PRO plans' seeded description disagrees with V030");
        assertTrue(seed.contains("AI access with 250k daily token quota."),
                "PREMIUM_PLUS's seeded description disagrees with V030");

        // And nothing may still claim the numbers V030 replaced.
        assertTrue(!seed.contains("30k daily token quota"),
                "a seeded plan still advertises the pre-V030 quota");
        assertTrue(!seed.contains("60k daily token quota"),
                "a seeded plan still advertises the pre-V030 quota");
        assertTrue(!seed.contains("1500 daily AI token quota"),
                "the free plan still advertises the quota V023 set and V030 corrected");
    }
}
