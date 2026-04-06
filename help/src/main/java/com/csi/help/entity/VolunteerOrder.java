package com.csi.help.entity;

import java.time.LocalDateTime;

/**
 * 志愿者订单实体
 */
public class VolunteerOrder {
    private String id;
    private String requestId;
    private String volunteerId;
    private String volunteerName;
    private String helpSeekerId;
    private String helpSeekerName;
    private String helpSeekerPhone;
    private String type;
    private String title;
    private String description;
    private String location;
    private Double latitude;
    private Double longitude;
    private String status;
    private LocalDateTime acceptedAt;
    private LocalDateTime startedAt;
    private LocalDateTime completedAt;
    private Integer estimatedDuration;
    private Integer actualDuration;
    private Double distance;
    private Integer rating;
    private String feedback;
    private String images;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    /**
     * \u6c42\u52a9\u8005\u662f\u5426\u5df2\u5bf9\u5fd7\u613f\u8005\u8bc4\u4ef7\uff08\u4e0d\u843d\u5e93\uff0c\u5217\u8868/\u8be6\u60c5\u63a5\u53e3\u586b\u5145\uff09
     */
    private Boolean seekerReviewed;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getRequestId() {
        return requestId;
    }

    public void setRequestId(String requestId) {
        this.requestId = requestId;
    }

    public String getVolunteerId() {
        return volunteerId;
    }

    public void setVolunteerId(String volunteerId) {
        this.volunteerId = volunteerId;
    }

    public String getVolunteerName() {
        return volunteerName;
    }

    public void setVolunteerName(String volunteerName) {
        this.volunteerName = volunteerName;
    }

    public String getHelpSeekerId() {
        return helpSeekerId;
    }

    public void setHelpSeekerId(String helpSeekerId) {
        this.helpSeekerId = helpSeekerId;
    }

    public String getHelpSeekerName() {
        return helpSeekerName;
    }

    public void setHelpSeekerName(String helpSeekerName) {
        this.helpSeekerName = helpSeekerName;
    }

    public String getHelpSeekerPhone() {
        return helpSeekerPhone;
    }

    public void setHelpSeekerPhone(String helpSeekerPhone) {
        this.helpSeekerPhone = helpSeekerPhone;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getAcceptedAt() {
        return acceptedAt;
    }

    public void setAcceptedAt(LocalDateTime acceptedAt) {
        this.acceptedAt = acceptedAt;
    }

    public LocalDateTime getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(LocalDateTime startedAt) {
        this.startedAt = startedAt;
    }

    public LocalDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(LocalDateTime completedAt) {
        this.completedAt = completedAt;
    }

    public Integer getEstimatedDuration() {
        return estimatedDuration;
    }

    public void setEstimatedDuration(Integer estimatedDuration) {
        this.estimatedDuration = estimatedDuration;
    }

    public Integer getActualDuration() {
        return actualDuration;
    }

    public void setActualDuration(Integer actualDuration) {
        this.actualDuration = actualDuration;
    }

    public Double getDistance() {
        return distance;
    }

    public void setDistance(Double distance) {
        this.distance = distance;
    }

    public Integer getRating() {
        return rating;
    }

    public void setRating(Integer rating) {
        this.rating = rating;
    }

    public String getFeedback() {
        return feedback;
    }

    public void setFeedback(String feedback) {
        this.feedback = feedback;
    }

    public String getImages() {
        return images;
    }

    public void setImages(String images) {
        this.images = images;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public Boolean getSeekerReviewed() {
        return seekerReviewed;
    }

    public void setSeekerReviewed(Boolean seekerReviewed) {
        this.seekerReviewed = seekerReviewed;
    }
}
