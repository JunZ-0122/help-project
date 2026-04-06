package com.csi.help.vo;

/**
 * 求助者详情页：状态说明横幅（匹配中 / 已出发等）
 */
public class SeekerBannerVo {
    /** blue | orange */
    private String tone;
    private String title;
    private String subtitle;

    public String getTone() {
        return tone;
    }

    public void setTone(String tone) {
        this.tone = tone;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getSubtitle() {
        return subtitle;
    }

    public void setSubtitle(String subtitle) {
        this.subtitle = subtitle;
    }
}
