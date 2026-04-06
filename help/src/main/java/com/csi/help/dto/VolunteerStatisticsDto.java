package com.csi.help.dto;

/**
 * \u5fd7\u613f\u8005\u4e2a\u4eba\u4e2d\u5fc3\u7edf\u8ba1\uff08\u670d\u52a1\u6b21\u6570\u3001\u6ee1\u610f\u5ea6\u3001\u670d\u52a1\u65f6\u957f\uff09
 */
public class VolunteerStatisticsDto {
    /** \u5df2\u5b8c\u6210\u8ba2\u5355\u6570\uff08\u670d\u52a1\u6b21\u6570\uff09 */
    private long serviceCount;
    /** \u6ee1\u610f\u5ea6 0-100\uff0c\u6c42\u52a9\u8005\u8bc4\u4ef7\u5747\u503c\u63a8\u7b97\uff1b\u65e0\u8bc4\u4ef7\u65f6\u53ef\u4e3a null */
    private Integer satisfactionPercent;
    /** \u7d2f\u8ba1\u670d\u52a1\u65f6\u957f\uff08\u5c0f\u65f6\uff0c\u4f18\u5148\u4ece\u5df2\u5b8c\u6210\u8ba2\u5355 actual_duration \u6c47\u603b\uff0c\u5426\u5219 users.volunteer_hours\uff09 */
    private double serviceHoursTotal;

    public long getServiceCount() {
        return serviceCount;
    }

    public void setServiceCount(long serviceCount) {
        this.serviceCount = serviceCount;
    }

    public Integer getSatisfactionPercent() {
        return satisfactionPercent;
    }

    public void setSatisfactionPercent(Integer satisfactionPercent) {
        this.satisfactionPercent = satisfactionPercent;
    }

    public double getServiceHoursTotal() {
        return serviceHoursTotal;
    }

    public void setServiceHoursTotal(double serviceHoursTotal) {
        this.serviceHoursTotal = serviceHoursTotal;
    }
}
