package com.csi.help.service;

import cn.hutool.core.util.IdUtil;
import com.csi.help.common.PageResult;
import com.csi.help.entity.HelpRequest;
import com.csi.help.entity.Review;
import com.csi.help.entity.User;
import com.csi.help.entity.VolunteerOrder;
import com.csi.help.mapper.HelpRequestMapper;
import com.csi.help.mapper.ReviewMapper;
import com.csi.help.mapper.UserMapper;
import com.csi.help.mapper.VolunteerOrderMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;

@Service
public class VolunteerOrderService {

    @Autowired
    private VolunteerOrderMapper volunteerOrderMapper;

    @Autowired
    private HelpRequestMapper helpRequestMapper;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private ReviewMapper reviewMapper;

    @Transactional
    public VolunteerOrder acceptOrder(String requestId, String volunteerId) {
        VolunteerOrder existingOrder = volunteerOrderMapper.findByRequestId(requestId);
        if (existingOrder != null) {
            throw new RuntimeException("\u8be5\u6c42\u52a9\u8bf7\u6c42\u5df2\u88ab\u63a5\u5355");
        }

        HelpRequest helpRequest = helpRequestMapper.findById(requestId);
        if (helpRequest == null) {
            throw new RuntimeException("\u6c42\u52a9\u8bf7\u6c42\u4e0d\u5b58\u5728");
        }
        if (!"pending".equals(helpRequest.getStatus())) {
            throw new RuntimeException("\u5f53\u524d\u6c42\u52a9\u72b6\u6001\u4e0d\u53ef\u63a5\u5355");
        }

        User volunteer = userMapper.findById(volunteerId);
        if (volunteer == null) {
            throw new RuntimeException("\u5fd7\u613f\u8005\u4e0d\u5b58\u5728");
        }

        VolunteerOrder order = new VolunteerOrder();
        order.setId(IdUtil.simpleUUID());
        order.setRequestId(requestId);
        order.setVolunteerId(volunteerId);
        order.setVolunteerName(volunteer.getName());
        order.setHelpSeekerId(helpRequest.getUserId());
        order.setHelpSeekerName(helpRequest.getUserName());
        order.setHelpSeekerPhone(helpRequest.getUserPhone());
        order.setType(helpRequest.getType());
        order.setTitle(helpRequest.getTitle());
        order.setDescription(helpRequest.getDescription());
        order.setLocation(helpRequest.getLocation());
        order.setLatitude(helpRequest.getLatitude());
        order.setLongitude(helpRequest.getLongitude());
        order.setStatus("accepted");
        order.setAcceptedAt(LocalDateTime.now());

        volunteerOrderMapper.insert(order);
        helpRequestMapper.updateStatus(requestId, "assigned");

        return order;
    }

    public List<VolunteerOrder> getMyOrders(String volunteerId, String status) {
        List<VolunteerOrder> list = volunteerOrderMapper.findByVolunteerId(volunteerId, status);
        enrichSeekerReviewFlags(list);
        return list;
    }

    public PageResult<VolunteerOrder> getMyOrdersPage(String volunteerId, String status,
                                                      int page, int pageSize) {
        int offset = (page - 1) * pageSize;
        long total = volunteerOrderMapper.countByVolunteerId(volunteerId, status);
        List<VolunteerOrder> items = volunteerOrderMapper.findByVolunteerIdPage(
                volunteerId, status, offset, pageSize);
        enrichSeekerReviewFlags(items);
        return new PageResult<>(items, total, page, pageSize);
    }

    /**
     * \u586b\u5145 seekerReviewed\uff0c\u5e76\u5bf9\u5386\u53f2\u6570\u636e\u4ece reviews \u8865\u9f50 rating
     */
    private void enrichSeekerReviewFlags(List<VolunteerOrder> list) {
        if (list == null || list.isEmpty()) {
            return;
        }
        for (VolunteerOrder o : list) {
            boolean reviewed = o.getRating() != null;
            if (!reviewed && "completed".equals(o.getStatus())) {
                Review r = reviewMapper.findByOrderIdAndRevieweeId(o.getId(), o.getVolunteerId());
                if (r != null) {
                    o.setRating(r.getRating());
                    reviewed = true;
                }
            }
            o.setSeekerReviewed(reviewed);
        }
    }

    public VolunteerOrder getById(String id) {
        VolunteerOrder o = volunteerOrderMapper.findById(id);
        if (o != null) {
            enrichSeekerReviewFlags(Collections.singletonList(o));
        }
        return o;
    }

    @Transactional
    public void updateStatus(String id, String status) {
        VolunteerOrder order = volunteerOrderMapper.findById(id);
        if (order == null) {
            throw new RuntimeException("\u8ba2\u5355\u4e0d\u5b58\u5728");
        }
        if ("in-progress".equals(status) && !"accepted".equals(order.getStatus())) {
            throw new RuntimeException("\u5f53\u524d\u8ba2\u5355\u4e0d\u80fd\u5f00\u59cb\u670d\u52a1");
        }
        volunteerOrderMapper.updateStatus(id, status);
        if ("in-progress".equals(status)) {
            helpRequestMapper.updateStatus(order.getRequestId(), "in-progress");
        }
    }

    @Transactional
    public void complete(String id, String feedback) {
        VolunteerOrder order = volunteerOrderMapper.findById(id);
        if (order == null) {
            throw new RuntimeException("\u8ba2\u5355\u4e0d\u5b58\u5728");
        }
        if (!"in-progress".equals(order.getStatus())) {
            throw new RuntimeException("\u53ea\u6709\u8fdb\u884c\u4e2d\u7684\u8ba2\u5355\u53ef\u4ee5\u5b8c\u6210");
        }
        volunteerOrderMapper.complete(id, feedback);
        helpRequestMapper.updateStatus(order.getRequestId(), "completed");
    }

    public VolunteerOrder getByRequestId(String requestId) {
        return volunteerOrderMapper.findByRequestId(requestId);
    }
}
