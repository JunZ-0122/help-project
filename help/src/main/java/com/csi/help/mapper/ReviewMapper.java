package com.csi.help.mapper;

import com.csi.help.entity.Review;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;

/**
 * 评价 Mapper
 */
@Mapper
public interface ReviewMapper {
    
    /**
     * 插入评价
     */
    int insert(Review review);
    
    /**
     * 根据订单 ID 查询评价
     */
    Review findByOrderId(@Param("orderId") String orderId);

    Review findByOrderIdAndReviewerId(@Param("orderId") String orderId,
                                      @Param("reviewerId") String reviewerId);

    /**
     * \u6309\u8ba2\u5355\u4e0e\u88ab\u8bc4\u4ef7\u4eba\uff08\u5fd7\u613f\u8005\uff09\u67e5\u8be2\uff0c\u7528\u4e8e\u6c42\u52a9\u8005\u8bc4\u4ef7\u5fd7\u613f\u8005
     */
    Review findByOrderIdAndRevieweeId(@Param("orderId") String orderId,
                                      @Param("revieweeId") String revieweeId);
    
    /**
     * 回复评价
     */
    int reply(@Param("id") String id, @Param("replyContent") String replyContent);

    /**
     * \u6c42\u52a9\u8005\u5bf9\u5fd7\u613f\u8005\u7684\u8bc4\u5206\u5747\u503c\uff081-5\uff09
     */
    Double avgRatingByRevieweeId(@Param("revieweeId") String revieweeId);

    /**
     * \u533a\u95f4\u5185\u5bf9\u5fd7\u613f\u8005\u8bc4\u4ef7\u7684\u5e73\u5747\u661f\u7ea7\uff081-5\uff09
     */
    Double avgRatingCreatedBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    /**
     * 某志愿者在区间内收到的评价均值（1-5），用于本月优秀志愿者满意度
     */
    Double avgRatingByRevieweeIdBetween(@Param("revieweeId") String revieweeId,
                                        @Param("start") LocalDateTime start,
                                        @Param("end") LocalDateTime end);
}
