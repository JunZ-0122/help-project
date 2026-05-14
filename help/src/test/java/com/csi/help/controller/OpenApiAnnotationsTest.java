package com.csi.help.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;

import java.lang.reflect.Method;
import java.util.List;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class OpenApiAnnotationsTest {

    private static final List<Class<?>> PUBLIC_CONTROLLERS = List.of(
            AuthController.class,
            GeocodeController.class
    );

    private static final List<Class<?>> PROTECTED_CONTROLLERS = List.of(
            ChatMessageController.class,
            CommunityController.class,
            EmergencyController.class,
            HelpRequestController.class,
            ReviewController.class,
            UserController.class,
            VolunteerController.class,
            VolunteerOrderController.class
    );

    @Test
    void everyControllerDeclaresATag() {
        Stream.concat(PUBLIC_CONTROLLERS.stream(), PROTECTED_CONTROLLERS.stream()).forEach(controller -> {
            Tag tag = controller.getAnnotation(Tag.class);
            assertNotNull(tag, controller.getSimpleName() + " is missing @Tag");
            assertFalse(tag.name().isBlank(), controller.getSimpleName() + " tag name should not be blank");
        });
    }

    @Test
    void protectedControllersDeclareBearerSecurity() {
        PROTECTED_CONTROLLERS.forEach(controller -> {
            SecurityRequirement securityRequirement = controller.getAnnotation(SecurityRequirement.class);
            assertNotNull(securityRequirement, controller.getSimpleName() + " is missing @SecurityRequirement");
            assertEquals("bearerAuth", securityRequirement.name());
        });
    }

    @Test
    void everyMappedMethodHasNonBlankSummary() {
        Stream.concat(PUBLIC_CONTROLLERS.stream(), PROTECTED_CONTROLLERS.stream()).forEach(controller -> {
            for (Method method : controller.getDeclaredMethods()) {
                if (hasHttpMapping(method)) {
                    Operation operation = method.getAnnotation(Operation.class);
                    assertNotNull(operation, controller.getSimpleName() + "#" + method.getName() + " is missing @Operation");
                    assertFalse(operation.summary().isBlank(), controller.getSimpleName() + "#" + method.getName() + " summary should not be blank");
                }
            }
        });
    }

    private boolean hasHttpMapping(Method method) {
        return method.isAnnotationPresent(GetMapping.class)
                || method.isAnnotationPresent(PostMapping.class)
                || method.isAnnotationPresent(PutMapping.class)
                || method.isAnnotationPresent(DeleteMapping.class);
    }
}
