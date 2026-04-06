package com.csi.help.vo;

/**
 * 求助者详情页：进度时间线节点
 */
public class SeekerTimelineItemVo {
    /** 展示文案，如「发布求助」 */
    private String label;
    /** HH:mm，未到阶段可为 null */
    private String time;
    /** done | current | upcoming */
    private String state;

    public String getLabel() {
        return label;
    }

    public void setLabel(String label) {
        this.label = label;
    }

    public String getTime() {
        return time;
    }

    public void setTime(String time) {
        this.time = time;
    }

    public String getState() {
        return state;
    }

    public void setState(String state) {
        this.state = state;
    }
}
