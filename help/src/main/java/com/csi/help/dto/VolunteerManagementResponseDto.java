package com.csi.help.dto;

import java.util.ArrayList;
import java.util.List;

public class VolunteerManagementResponseDto {
    private VolunteerManagementSummaryDto summary = new VolunteerManagementSummaryDto();
    private List<VolunteerManagementRowDto> volunteers = new ArrayList<>();

    public VolunteerManagementSummaryDto getSummary() {
        return summary;
    }

    public void setSummary(VolunteerManagementSummaryDto summary) {
        this.summary = summary;
    }

    public List<VolunteerManagementRowDto> getVolunteers() {
        return volunteers;
    }

    public void setVolunteers(List<VolunteerManagementRowDto> volunteers) {
        this.volunteers = volunteers;
    }
}
