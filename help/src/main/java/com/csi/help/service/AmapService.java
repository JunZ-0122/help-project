package com.csi.help.service;

import com.csi.help.config.AmapProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.List;
import java.util.Map;

/**
 * 高德 Web 服务：地理编码、逆地理编码、距离计算
 */
@Service
public class AmapService {

    private static final Logger log = LoggerFactory.getLogger(AmapService.class);

    private final AmapProperties amapProperties;
    private final RestTemplate restTemplate;

    public AmapService(AmapProperties amapProperties, RestTemplate restTemplate) {
        this.amapProperties = amapProperties;
        this.restTemplate = restTemplate;
    }

    /**
     * 地理编码：地址 -> 经纬度
     * @param address 结构化地址（省市区+街道门牌等）
     * @return [经度, 纬度]，解析失败返回 null
     */
    @SuppressWarnings("unchecked")
    public double[] geocode(String address) {
        if (address == null || address.isBlank()) {
            return null;
        }
        String key = amapProperties.getWebServiceKey();
        if (key == null || key.isBlank()) {
            log.warn("amap.web-service-key not set, skip geocode");
            return null;
        }
        String url = UriComponentsBuilder.fromHttpUrl(amapProperties.getWebServiceHost() + "/v3/geocode/geo")
                .queryParam("key", key)
                .queryParam("address", address)
                .build()
                .toUriString();
        try {
            ResponseEntity<Map> resp = restTemplate.getForEntity(url, Map.class);
            Map<String, Object> body = resp.getBody();
            if (body == null || !"1".equals(String.valueOf(body.get("status")))) {
                log.warn("amap geocode failed: {}", body != null ? body.get("info") : "null body");
                return null;
            }
            Object geocodes = body.get("geocodes");
            if (!(geocodes instanceof List) || ((List<?>) geocodes).isEmpty()) {
                return null;
            }
            Object first = ((List<?>) geocodes).get(0);
            if (!(first instanceof Map)) {
                return null;
            }
            String location = (String) ((Map<?, ?>) first).get("location");
            if (location == null || !location.contains(",")) {
                return null;
            }
            String[] parts = location.split(",");
            if (parts.length != 2) {
                return null;
            }
            double lng = Double.parseDouble(parts[0].trim());
            double lat = Double.parseDouble(parts[1].trim());
            return new double[]{lng, lat};
        } catch (Exception e) {
            log.error("amap geocode error, address={}", address, e);
            return null;
        }
    }

    /**
     * 逆地理编码：经纬度 -> 地址
     * @param longitude 经度
     * @param latitude  纬度
     * @return 格式化地址字符串，解析失败返回 null
     */
    @SuppressWarnings("unchecked")
    public String regeo(double longitude, double latitude) {
        String key = amapProperties.getWebServiceKey();
        if (key == null || key.isBlank()) {
            log.warn("amap.web-service-key not set, skip regeo");
            return null;
        }
        String location = longitude + "," + latitude;
        String url = UriComponentsBuilder.fromHttpUrl(amapProperties.getWebServiceHost() + "/v3/geocode/regeo")
                .queryParam("key", key)
                .queryParam("location", location)
                .build()
                .toUriString();
        try {
            ResponseEntity<Map> resp = restTemplate.getForEntity(url, Map.class);
            Map<String, Object> body = resp.getBody();
            if (body == null || !"1".equals(String.valueOf(body.get("status")))) {
                log.warn("amap regeo failed: {}", body != null ? body.get("info") : "null body");
                return null;
            }
            Object regeocode = body.get("regeocode");
            if (!(regeocode instanceof Map)) {
                return null;
            }
            return (String) ((Map<?, ?>) regeocode).get("formatted_address");
        } catch (Exception e) {
            log.error("amap regeo error, location={}", location, e);
            return null;
        }
    }

    /**
     * 两点直线距离（Haversine 公式），单位：公里
     */
    public static double distanceKm(double lng1, double lat1, double lng2, double lat2) {
        final double R = 6371.0; // 地球半径 km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
