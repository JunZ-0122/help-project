package com.csi.help.dto;

import java.util.ArrayList;
import java.util.List;

public class DispatchVolunteerProfileDto {
    private String id;
    private String name;
    private String avatar;
    private String location;
    private int satisfaction;
    private List<VolunteerSkillTagDto> skills = new ArrayList<>();

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

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
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
}
