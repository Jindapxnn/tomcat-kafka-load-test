import http from "k6/http";
import { check, sleep, group } from "k6";

export let options = {
  // กำหนดล่วงหน้าว่าจะยิงกี่คน (Virtual Users)
  stages: [
    { duration: "10s", target: 100 }, // 10 วินาทีแรก ค่อยๆ เพิ่มคนเป็น 20
    { duration: "30s", target: 1000 }, // 30 วินาทีต่อมา อัดโหลดที่ 100 คนพร้อมกัน
    { duration: "10s", target: 0 }, // 10 วินาทีสุดท้าย ค่อยๆ ลดคนลง
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"], // ต้องมี Error น้อยกว่า 1%
    http_req_duration: ["p(95)<500"], // 95% ของการยิงต้องเร็วกว่า 1 วินาที

    // แยกเก็บสถิติแยกตามกลุ่มที่กำหนดในโค้ด
    'http_req_duration{group:::Database_Path}': ['p(95)<500'],
    'http_req_duration{group:::Kafka_Path}': ['p(95)<200'],
  },
};

export default function () {
  const type = Math.random() < 0.5 ? "db" : "mq";
  const orderId = `ORD-${Math.floor(Math.random() * 1000000)}`;
  const url = `http://java-app:8080/api.jsp?type=${type}&order_id=${orderId}`;

  // ใช้ group ครอบ เพื่อแยกสถิติใน report
  group(type === "db" ? "Database_Path" : "Kafka_Path", function () {
    let res = http.get(url);

    check(res, {
      "status is 200": (r) => r.status === 200,
      "mode is correct": (r) =>
        r.json().mode === (type === "db" ? "database" : "kafka"),
    });
  });

  sleep(0.1);
}
