package com.csi.help.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

/**
 * 本地/演示：若库中无任何 pending 求助，则插入一条带经纬度的演示数据，避免志愿者端列表为空。
 * 生产环境请设置 {@code help.seed-demo-if-empty=false}。
 */
@Component
@Order(Integer.MAX_VALUE)
public class DemoHelpDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoHelpDataSeeder.class);

    private final DataSource dataSource;

    @Value("${help.seed-demo-if-empty:true}")
    private boolean seedIfEmpty;

    public DemoHelpDataSeeder(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void run(ApplicationArguments args) {
        if (!seedIfEmpty) {
            return;
        }
        try (Connection conn = dataSource.getConnection()) {
            long pending = countPending(conn);
            if (pending > 0) {
                return;
            }
            insertDemoUserIfMissing(conn);
            insertDemoRequestIfMissing(conn);
            log.info("[DemoHelpDataSeeder] 已插入演示待接单求助（无 pending 数据时自动填充）");
        } catch (Exception e) {
            log.warn("[DemoHelpDataSeeder] 跳过演示数据插入: {}", e.getMessage());
        }
    }

    private static long countPending(Connection conn) throws Exception {
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM help_requests WHERE status = 'pending'")) {
            if (rs.next()) {
                return rs.getLong(1);
            }
            return 0;
        }
    }

    private static void insertDemoUserIfMissing(Connection conn) throws Exception {
        String sql = "INSERT IGNORE INTO users (id, name, phone, password, role, status, created_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, NOW())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "user001");
            ps.setString(2, "\u5f20\u4e09");
            ps.setString(3, "13800138001");
            ps.setString(4, "e10adc3949ba59abbe56e057f20f883e");
            ps.setString(5, "help-seeker");
            ps.setString(6, "online");
            ps.executeUpdate();
        }
    }

    private static void insertDemoRequestIfMissing(Connection conn) throws Exception {
        String sql = "INSERT IGNORE INTO help_requests ("
                + "id, user_id, user_name, user_phone, type, title, description, "
                + "location, latitude, longitude, urgency, status, created_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "req_demo_emergency_ui");
            ps.setString(2, "user001");
            ps.setString(3, "\u5f20\u4e09");
            ps.setString(4, "13800138001");
            ps.setString(5, "emergency");
            ps.setString(6, "\u7d27\u6025\u6c42\u52a9");
            ps.setString(7, "\u3010\u6f14\u793a\u6570\u636e\u3011\u9700\u5c3d\u5feb\u534f\u52a9\uff0c\u7528\u4e8e\u5fd7\u613f\u8005\u9996\u9875\u7d27\u6025\u4efb\u52a1\u7ea2\u6846\u5c55\u793a\u3002");
            ps.setString(8, "\u5317\u4eac\u5e02\u671d\u9633\u533a\u5efa\u56fd\u8def1\u53f7\u9644\u8fd1");
            ps.setBigDecimal(9, new java.math.BigDecimal("39.9042000"));
            ps.setBigDecimal(10, new java.math.BigDecimal("116.4074000"));
            ps.setString(11, "emergency");
            ps.setString(12, "pending");
            ps.executeUpdate();
        }
    }
}
