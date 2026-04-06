package com.csi.help.controller;

import com.csi.help.common.Result;
import com.csi.help.entity.Review;
import com.csi.help.service.ReviewService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 评价控制器
 */
@RestController
@RequestMapping("/api/reviews")
public class ReviewController {

    @Autowired
    private ReviewService reviewService;

    /**
     * 创建评价
     */
    @PostMapping({"", "/"})
    public Result<Review> create(@RequestBody Review review,
                                   @RequestAttribute("userId") String reviewerId) {
        review.setReviewerId(reviewerId);
        Review savedReview = reviewService.create(review);
        return Result.success(savedReview);
    }

    /**
     * \u5f53\u524d\u7528\u6237\u5bf9\u8be5\u8ba2\u5355\u53d1\u8d77\u7684\u8bc4\u4ef7\uff08\u6211\u8bc4\u4ed6\u4eba\uff09
     */
    @GetMapping("/order/{orderId}")
    public Result<Review> getMyReviewForOrder(@PathVariable String orderId,
                                              @RequestAttribute("userId") String userId) {
        Review review = reviewService.getMyReviewAsReviewer(orderId, userId);
        return Result.success(review);
    }

    /**
     * \u5f53\u524d\u7528\u6237\u4f5c\u4e3a\u88ab\u8bc4\u4ef7\u4eba\u6536\u5230\u7684\u8bc4\u4ef7\uff08\u5982\u6c42\u52a9\u8005\u8bc4\u5fd7\u613f\u8005\u540e\u5fd7\u613f\u67e5\u770b\uff09
     */
    @GetMapping("/order/{orderId}/received")
    public Result<Review> getReviewReceived(@PathVariable String orderId,
                                            @RequestAttribute("userId") String userId) {
        Review review = reviewService.getReviewReceivedByUser(orderId, userId);
        return Result.success(review);
    }

    /**
     * 回复评价
     */
    @PostMapping("/{id}/reply")
    public Result<Void> reply(@PathVariable String id,
                                @RequestBody Map<String, String> params) {
        String replyContent = params.get("replyContent");
        reviewService.reply(id, replyContent);
        return Result.success();
    }
}
