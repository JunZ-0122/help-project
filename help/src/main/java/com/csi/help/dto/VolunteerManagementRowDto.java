package com.csi.help.dto;

import java.util.ArrayList;
import java.util.List;

public class VolunteerManagementRowDto {
    private String id;
    private String name;
    private String avatar;
    private String phoneMasked;
    private String location;
    /** online | in_service | offline */
    private String uiStatus;
    private int serviceCount;
    private int satisfaction;
    private List<VolunteerSkillTagDto> skills = new ArrayList<>();
    private boolean quickDispatchEnabled;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAvatar() {
        return avatar;
    }

    public void setAvatar(String avatar) {
        this.avatar = avatar;
    }

    public String getPhoneMasked() {
        return phoneMasked;
    }

    public void setPhoneMasked(String phoneMasked) {
        this.phoneMasked = phoneMasked;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getUiStatus() {
        return uiStatus;
    }

    public void setUiStatus(String uiStatus) {
        this.uiStatus = uiStatus;
    }

    public int getServiceCount() {
        return serviceCount;
    }

    public void setServiceCount(int serviceCount) {
        this.serviceCount = serviceCount;
    }

    public int getSatisfaction() {
        return satisfaction;
    }

    public void setSatisfaction(int satisfaction) {
        this.satisfaction = satisfaction;
    }

    public List<VolunteerSkillTagDto> getSkills() {
        return skills;
    }

    public void setSkills(List<VolunteerSkillTagDto> skills) {
        this.skills = skills;
    }

    public boolean isQuickDispatchEnabled() {
        return quickDispatchEnabled;
    }

    public void setQuickDispatchEnabled(boolean quickDispatchEnabled) {
        this.quickDispatchEnabled = quickDispatchEnabled;
    }
}
