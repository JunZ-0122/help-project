package com.csi.help.mapper;

import com.csi.help.entity.VolunteerOrder;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * 志愿者订单 Mapper
 */
@Mapper
public interface VolunteerOrderMapper {
    
    /**
     * 插入订单
     */
    int insert(VolunteerOrder order);
    
    /**
     * 根据 ID 查询
     */
    VolunteerOrder findById(@Param("id") String id);
    
    /**
     * 根据请求 ID 查询
     */
    VolunteerOrder findByRequestId(@Param("requestId") String requestId);
    
    /**
     * 查询志愿者的订单列表
     */
    List<VolunteerOrder> findByVolunteerId(@Param("volunteerId") String volunteerId,
                                             @Param("status") String status);

    long countByVolunteerId(@Param("volunteerId") String volunteerId,
                            @Param("status") String status);

    List<VolunteerOrder> findByVolunteerIdPage(@Param("volunteerId") String volunteerId,
                                               @Param("status") String status,
                                               @Param("offset") int offset,
                                               @Param("pageSize") int pageSize);
    
    /**
     * \u6c42\u52a9\u8005\u8bc4\u4ef7\u5fd7\u613f\u8005\u540e\u540c\u6b65\u661f\u7ea7\u5230\u8ba2\u5355\u8868
     */
    int updateSeekerRating(@Param("id") String id, @Param("rating") Integer rating);

    /**
     * \u5df2\u5b8c\u6210\u8ba2\u5355 actual_duration\uff08\u5206\u949f\uff09\u6c42\u548c
     */
    Integer sumActualDurationMinutes(@Param("volunteerId") String volunteerId);
    
    /**
     * 更新订单
     */
    int update(VolunteerOrder order);
    
    /**
     * 更新状态
     */
    int updateStatus(@Param("id") String id, @Param("status") String status);
    
    /**
     * 完成订单
     */
    int complete(@Param("id") String id, @Param("feedback") String feedback);

    /**
     * 区间内已完成订单数（用于统计：本月帮扶次数等）
     */
    long countCompletedBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * 区间内至少完成一单的去重志愿者数（活跃志愿者）
     */
    long countDistinctVolunteersCompletedBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * 某日完成的订单数（本周趋势）
     */
    long countCompletedOnLocalDate(@Param("day") LocalDate day);

    /**
     * 区间内各志愿者完成单数，按单数降序
     */
    List<Map<String, Object>> volunteerCompletedCountsBetween(@Param("start") LocalDateTime start,
                                                              @Param("end") LocalDateTime end,
                                                              @Param("limit") int limit);

    /**
     * 从历史完成单推断志愿者擅长类型（无 volunteer_skills 记录时的兜底）
     */
    List<String> findDistinctCompletedTypesByVolunteer(@Param("volunteerId") String volunteerId);
}
