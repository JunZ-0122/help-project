package com.csi.help.dto;

import com.csi.help.vo.SeekerTimelineItemVo;

import java.util.List;

/**
 * 手表端紧急求助状态查询结果
 */
public class WatchRequestStatusDto {
    private String requestId;
    private String stage;
    private String status;
    private String title;
    private String location;
    private String updatedAt;
    private String volunteerName;
    private String volunteerPhoneMasked;
    private Double distanceKm;
    private Integer etaMinutes;
    private List<SeekerTimelineItemVo> timeline;
    private String message;

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String getStage() {
        return stage;
    }

    public void setStage(String stage) {
        this.stage = stage;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(String updatedAt) {
        this.updatedAt = updatedAt;
    }

    public String getVolunteerName() {
        return volunteerName;
    }

    public void setVolunteerName(String volunteerName) {
        this.volunteerName = volunteerName;
    }

    public String getVolunteerPhoneMasked() {
        return volunteerPhoneMasked;
    }

    public void setVolunteerPhoneMasked(String volunteerPhoneMasked) {
        this.volunteerPhoneMasked = volunteerPhoneMasked;
    }

    public Double getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(Double distanceKm) {
        this.distanceKm = distanceKm;
    }

    public Integer getEtaMinutes() {
        return etaMinutes;
    }

    public void setEtaMinutes(Integer etaMinutes) {
        this.etaMinutes = etaMinutes;
    }

    public List<SeekerTimelineItemVo> getTimeline() {
        return timeline;
    }

    public void setTimeline(List<SeekerTimelineItemVo> timeline) {
        this.timeline = timeline;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
