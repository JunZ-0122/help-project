package com.csi.help.service;

import cn.hutool.core.util.IdUtil;
import com.csi.help.entity.Review;
import com.csi.help.entity.User;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.mapper.ReviewMapper;
import com.csi.help.mapper.UserMapper;
import com.csi.help.mapper.VolunteerOrderMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 评价服务
 */
@Service
public class ReviewService {

    @Autowired
    private ReviewMapper reviewMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private VolunteerOrderMapper volunteerOrderMapper;

    /**
     * 创建评价
     */
    @Transactional
    public Review create(Review review) {
        Review existingReview = reviewMapper.findByOrderIdAndReviewerId(
                review.getOrderId(), review.getReviewerId());
        if (existingReview != null) {
            throw new RuntimeException("\u8be5\u8ba2\u5355\u4e0b\u60a8\u5df2\u63d0\u4ea4\u8fc7\u8bc4\u4ef7");
        }

        // 获取评价者和被评价者信息
        User reviewer = userMapper.findById(review.getReviewerId());
        User reviewee = userMapper.findById(review.getRevieweeId());
        
        if (reviewer != null) {
            review.setReviewerName(reviewer.getName());
        }
        if (reviewee != null) {
            review.setRevieweeName(reviewee.getName());
        }

        review.setId(IdUtil.simpleUUID());
        reviewMapper.insert(review);

        VolunteerOrder order = volunteerOrderMapper.findById(review.getOrderId());
        if (order != null && order.getVolunteerId() != null
                && order.getVolunteerId().equals(review.getRevieweeId())) {
            volunteerOrderMapper.updateSeekerRating(order.getId(), review.getRating());
        }

        return review;
    }

    /**
     * \u5f53\u524d\u7528\u6237\u4f5c\u4e3a\u8bc4\u4ef7\u4eba\u5bf9\u8be5\u8ba2\u5355\u7684\u8bc4\u4ef7
     */
    public Review getMyReviewAsReviewer(String orderId, String reviewerId) {
        return reviewMapper.findByOrderIdAndReviewerId(orderId, reviewerId);
    }

    /**
     * \u5f53\u524d\u7528\u6237\u4f5c\u4e3a\u88ab\u8bc4\u4ef7\u4eba\u6536\u5230\u7684\u8bc4\u4ef7\uff08\u4f8b\u5982\u6c42\u52a9\u8005\u8bc4\u5fd7\u613f\u8005\uff09
     */
    public Review getReviewReceivedByUser(String orderId, String revieweeId) {
        return reviewMapper.findByOrderIdAndRevieweeId(orderId, revieweeId);
    }

    /**
     * 根据订单 ID 获取评价（\u4efb\u610f\u4e00\u6761\uff0c\u517c\u5bb9\u65e7\u903b\u8f91\uff09
     */
    public Review getByOrderId(String orderId) {
        return reviewMapper.findByOrderId(orderId);
    }

    /**
     * 回复评价
     */
    @Transactional
    public void reply(String id, String replyContent) {
        reviewMapper.reply(id, replyContent);
    }
}