package com.csi.help.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.tags.Tag;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    public static final String SECURITY_SCHEME_NAME = "bearerAuth";

    @Bean
    public OpenAPI helpOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Help System API")
                        .version("v1")
                        .description("OpenAPI description for Apifox import and local automation testing."))
                .components(new Components()
                        .addSecuritySchemes(SECURITY_SCHEME_NAME, new SecurityScheme()
                                .name("Authorization")
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList(SECURITY_SCHEME_NAME))
                .addTagsItem(new Tag().name("认证"))
                .addTagsItem(new Tag().name("求助请求"))
                .addTagsItem(new Tag().name("紧急求助"))
                .addTagsItem(new Tag().name("聊天"))
                .addTagsItem(new Tag().name("社区管理"))
                .addTagsItem(new Tag().name("用户"))
                .addTagsItem(new Tag().name("志愿者概览"))
                .addTagsItem(new Tag().name("志愿者订单"))
                .addTagsItem(new Tag().name("评价"))
                .addTagsItem(new Tag().name("地理编码"));
    }
}
