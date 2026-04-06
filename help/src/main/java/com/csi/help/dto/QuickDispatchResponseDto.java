package com.csi.help.dto;

import java.util.ArrayList;
import java.util.List;

public class QuickDispatchResponseDto {
    private DispatchVolunteerProfileDto volunteer;
    private List<DispatchScoredRequestDto> smartMatches = new ArrayList<>();
    private List<DispatchScoredRequestDto> otherPending = new ArrayList<>();

    public DispatchVolunteerProfileDto getVolunteer() {
        return volunteer;
    }

    public void setVolunteer(DispatchVolunteerProfileDto volunteer) {
        this.volunteer = volunteer;
    }

    public List<DispatchScoredRequestDto> getSmartMatches() {
        return smartMatches;
    }

    public void setSmartMatches(List<DispatchScoredRequestDto> smartMatches) {
        this.smartMatches = smartMatches;
    }

    public List<DispatchScoredRequestDto> getOtherPending() {
        return otherPending;
    }

    public void setOtherPending(List<DispatchScoredRequestDto> otherPending) {
        this.otherPending = otherPending;
    }
}
