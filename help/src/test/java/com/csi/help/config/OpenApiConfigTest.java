package com.csi.help.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class OpenApiConfigTest {

    @Test
    void buildsOpenApiMetadataForApifoxImport() {
        OpenApiConfig config = new OpenApiConfig();

        OpenAPI openAPI = config.helpOpenApi();

        assertEquals("Help System API", openAPI.getInfo().getTitle());
        assertEquals("v1", openAPI.getInfo().getVersion());
        assertEquals("OpenAPI description for Apifox import and local automation testing.", openAPI.getInfo().getDescription());
    }

    @Test
    void registersBearerSecurityScheme() {
        OpenApiConfig config = new OpenApiConfig();

        OpenAPI openAPI = config.helpOpenApi();
        SecurityScheme securityScheme = openAPI.getComponents()
                .getSecuritySchemes()
                .get(OpenApiConfig.SECURITY_SCHEME_NAME);

        assertNotNull(securityScheme);
        assertEquals(SecurityScheme.Type.HTTP, securityScheme.getType());
        assertEquals("bearer", securityScheme.getScheme());
        assertEquals("JWT", securityScheme.getBearerFormat());
        assertEquals("Authorization", securityScheme.getName());
        assertEquals(OpenApiConfig.SECURITY_SCHEME_NAME, openAPI.getSecurity().get(0).keySet().iterator().next());
    }
}
