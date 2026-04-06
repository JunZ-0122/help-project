package com.csi.help.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 高德 Web 服务配置
 */
@Component
@ConfigurationProperties(prefix = "amap")
public class AmapProperties {

    private String webServiceKey = "";
    private String webServiceHost = "https://restapi.amap.com";

    public String getWebServiceKey() {
        return webServiceKey;
    }

    public void setWebServiceKey(String webServiceKey) {
        this.webServiceKey = webServiceKey;
    }

    public String getWebServiceHost() {
        return webServiceHost;
    }

    public void setWebServiceHost(String webServiceHost) {
        this.webServiceHost = webServiceHost;
    }
}
