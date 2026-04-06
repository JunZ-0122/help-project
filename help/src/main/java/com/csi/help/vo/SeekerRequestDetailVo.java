package com.csi.help.vo;

import com.csi.help.entity.HelpRequest;

import java.util.List;

/**
 * 求助端「求助详情」聚合数据（列表仍用 /requests/my）
 */
public class SeekerRequestDetailVo {
    private HelpRequest request;
    /** 顶部胶囊文案：已发布 / 已接单 / 志愿者已出发 / 已完成 */
    private String badgeLabel;
    /** published | accepted | departed | completed | cancelled */
    private String badgeTone;
    /** 顶部右侧时间 yyyy-MM-dd HH:mm */
    private String headerTimeDisplay;
    private SeekerVolunteerVo volunteer;
    private SeekerBannerVo banner;
    /** 已出发时预计到达分钟，无则默认 5 */
    private Integer etaMinutes;
    private List<SeekerTimelineItemVo> timeline;

    public HelpRequest getRequest() {
        return request;
    }

    public void setRequest(HelpRequest request) {
        this.request = request;
    }

    public String getBadgeLabel() {
        return badgeLabel;
    }

    public void setBadgeLabel(String badgeLabel) {
        this.badgeLabel = badgeLabel;
    }

    public String getBadgeTone() {
        return badgeTone;
    }

    public void setBadgeTone(String badgeTone) {
        this.badgeTone = badgeTone;
    }

    public String getHeaderTimeDisplay() {
        return headerTimeDisplay;
    }

    public void setHeaderTimeDisplay(String headerTimeDisplay) {
        this.headerTimeDisplay = headerTimeDisplay;
    }

    public SeekerVolunteerVo getVolunteer() {
        return volunteer;
    }

    public void setVolunteer(SeekerVolunteerVo volunteer) {
        this.volunteer = volunteer;
    }

    public SeekerBannerVo getBanner() {
        return banner;
    }

    public void setBanner(SeekerBannerVo banner) {
        this.banner = banner;
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
}
