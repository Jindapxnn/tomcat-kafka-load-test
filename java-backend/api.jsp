<%@ page import="java.sql.*, java.util.Properties, org.apache.kafka.clients.producer.*" %>
<%@ page contentType="application/json;charset=UTF-8" language="java" %>
<%
    // Get value from request
    String orderId = request.getParameter("order_id");
    String type = request.getParameter("type"); // 'db' or 'mq'
    
    // Create JSON response
    StringBuilder jsonResponse = new StringBuilder("{");
    
    if (orderId == null || type == null) {
        response.setStatus(400);
        out.print("{\"error\": \"Missing parameters\"}");
        return;
    }

    try {
        if ("db".equals(type)) {
            // --- Logic: Direct DB (Synchronous) ---
            long startTime = System.currentTimeMillis();
            Class.forName("org.postgresql.Driver");
            try (Connection conn = DriverManager.getConnection("jdbc:postgresql://postgres_db:5432/tomcat-kafka", "admin", "admin")) {
                PreparedStatement ps = conn.prepareStatement("INSERT INTO orders (order_id, info) VALUES (?, ?)");
                ps.setString(1, orderId);
                ps.setString(2, "Direct DB Write");
                ps.executeUpdate();
            }
            long endTime = System.currentTimeMillis();
            jsonResponse.append("\"status\": \"success\", \"mode\": \"database\", \"latency_ms\": " + (endTime - startTime));

        } else if ("mq".equals(type)) {
            // --- Logic: Kafka (Asynchronous) ---
            long startTime = System.currentTimeMillis();
            Properties props = new Properties();
            props.put("bootstrap.servers", "kafka:9092");
            props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
            props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");
            
            try (KafkaProducer<String, String> producer = new KafkaProducer<>(props)) {
                String message = "{\"order_id\": \"" + orderId + "\", \"timestamp\": " + startTime + "}";
                producer.send(new ProducerRecord<>("orders-topic", orderId, message));
            }
            long endTime = System.currentTimeMillis();
            jsonResponse.append("\"status\": \"success\", \"mode\": \"kafka\", \"latency_ms\": " + (endTime - startTime));
        }

    } catch (Exception e) {
        response.setStatus(500);
        jsonResponse.append("\"status\": \"error\", \"message\": \"" + e.getMessage().replace("\"", "'") + "\"");
    }

    jsonResponse.append("}");
    out.print(jsonResponse.toString());
%>