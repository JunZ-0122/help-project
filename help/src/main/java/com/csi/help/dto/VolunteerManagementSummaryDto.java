package com.csi.help.dto;

public class VolunteerManagementSummaryDto {
    private int totalVolunteers;
    private int onlineCount;
    private int inServiceCount;
    private long weekServices;
    private double avgRating;

    public int getTotalVolunteers() {
        return totalVolunteers;
    }

    public void setTotalVolunteers(int totalVolunteers) {
        this.totalVolunteers = totalVolunteers;
    }

    public int getOnlineCount() {
        return onlineCount;
    }

    public void setOnlineCount(int onlineCount) {
        this.onlineCount = onlineCount;
    }

    public int getInServiceCount() {
        return inServiceCount;
    }

    public void setInServiceCount(int inServiceCount) {
        this.inServiceCount = inServiceCount;
    }

    public long getWeekServices() {
        return weekServices;
    }

    public void setWeekServices(long weekServices) {
        this.weekServices = weekServices;
    }

    public double getAvgRating() {
        return avgRating;
    }

    public void setAvgRating(double avgRating) {
        this.avgRating = avgRating;
    }
}
