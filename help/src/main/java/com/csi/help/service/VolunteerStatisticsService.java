package com.csi.help.service;

import com.csi.help.dto.VolunteerStatisticsDto;
import com.csi.help.entity.User;
import com.csi.help.mapper.ReviewMapper;
import com.csi.help.mapper.UserMapper;
import com.csi.help.mapper.VolunteerOrderMapper;
import org.springframework.stereotype.Service;

/**
 * \u5fd7\u613f\u8005\u4e2a\u4eba\u4e2d\u5fc3\u7edf\u8ba1
 */
@Service
public class VolunteerStatisticsService {

    private final VolunteerOrderMapper volunteerOrderMapper;
    private final ReviewMapper reviewMapper;
    private final UserMapper userMapper;

    public VolunteerStatisticsService(VolunteerOrderMapper volunteerOrderMapper,
                                      ReviewMapper reviewMapper,
                                      UserMapper userMapper) {
        this.volunteerOrderMapper = volunteerOrderMapper;
        this.reviewMapper = reviewMapper;
        this.userMapper = userMapper;
    }

    public VolunteerStatisticsDto getStatistics(String volunteerId) {
        User user = userMapper.findById(volunteerId);
        long completed = volunteerOrderMapper.countByVolunteerId(volunteerId, "completed");
        Integer sumMinutes = volunteerOrderMapper.sumActualDurationMinutes(volunteerId);
        double hours = 0.0;
        if (sumMinutes != null && sumMinutes > 0) {
            hours = sumMinutes / 60.0;
        } else if (user != null && user.getVolunteerHours() != null) {
            hours = user.getVolunteerHours().doubleValue();
        }

        Double avgSeekerRating = reviewMapper.avgRatingByRevieweeId(volunteerId);
        Integer satisfaction = null;
        if (avgSeekerRating != null && !avgSeekerRating.isNaN() && avgSeekerRating > 0) {
            satisfaction = (int) Math.round(avgSeekerRating / 5.0 * 100.0);
        } else if (user != null && user.getRating() != null && user.getRating() > 0) {
            satisfaction = (int) Math.round(user.getRating() / 5.0 * 100.0);
        }

        VolunteerStatisticsDto dto = new VolunteerStatisticsDto();
        dto.setServiceCount(completed);
        dto.setSatisfactionPercent(satisfaction);
        dto.setServiceHoursTotal(hours);
        return dto;
    }
}
