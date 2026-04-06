package com.csi.help.dto;

import com.csi.help.entity.HelpRequest;

/**
 * 求助请求 + 与参考点的距离（用于附近求助列表）
 */
public class HelpRequestWithDistanceDto {
    private HelpRequest request;
    /** 距离（公里） */
    private Double distance;

    public HelpRequestWithDistanceDto(HelpRequest request, Double distance) {
        this.request = request;
        this.distance = distance;
    }

    public HelpRequest getRequest() {
        return request;
    }

    public void setRequest(HelpRequest request) {
        this.request = request;
    }

    public Double getDistance() {
        return distance;
    }

    public void setDistance(Double distance) {
        this.distance = distance;
    }
}
