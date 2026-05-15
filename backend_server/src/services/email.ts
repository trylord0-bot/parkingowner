import nodemailer from "nodemailer";
import { config } from "../config/index.js";

const transporter = nodemailer.createTransport({
  host: config.SMTP_HOST,
  port: config.SMTP_PORT,
  secure: false,
  requireTLS: true,
  auth: config.SMTP_USER && config.SMTP_PASS
    ? { user: config.SMTP_USER, pass: config.SMTP_PASS }
    : undefined,
});

// SMTP 연결 검증 (서버 시작 시 자격증명 문제를 즉시 확인)
if (config.SMTP_HOST && config.SMTP_USER && config.SMTP_PASS) {
  transporter.verify().then(() => {
    console.log("✅ SMTP connection verified:", config.SMTP_HOST);
  }).catch((err: Error) => {
    console.error("❌ SMTP connection failed:", err.message);
    console.error("   Check SMTP_USER (Brevo login email) and SMTP_PASS (SMTP key)");
  });
}

export async function sendVerificationEmail(to: string, code: string) {
  await transporter.sendMail({
    from: config.SMTP_FROM,
    to,
    subject: "[ParkingOwner] 이메일 인증 코드",
    html: `
      <div style="font-family:sans-serif;max-width:480px;margin:0 auto;">
        <h2 style="color:#1a73e8;">이메일 인증</h2>
        <p>안녕하세요,</p>
        <p>아래 6자리 인증 코드를 앱에 입력해 주세요.</p>
        <div style="margin:24px 0;text-align:center;">
          <span style="display:inline-block;font-size:36px;font-weight:700;letter-spacing:12px;color:#1a1a1a;background:#f5f5f5;padding:16px 24px;border-radius:8px;">${code}</span>
        </div>
        <p style="color:#666;font-size:13px;">이 코드는 <strong>10분</strong> 동안 유효합니다.</p>
        <p style="color:#666;font-size:13px;">본인이 요청하지 않은 경우 이 이메일을 무시하세요.</p>
      </div>
    `,
  });
}

export async function sendPasswordResetEmail(to: string, token: string) {
  const url = `${config.APP_URL}/reset-password?token=${token}`;
  await transporter.sendMail({
    from: config.SMTP_FROM,
    to,
    subject: "[ParkingOwner] 비밀번호 재설정 안내",
    html: `
      <p>안녕하세요,</p>
      <p>비밀번호 재설정을 요청하셨습니다. 아래 버튼을 클릭하여 새 비밀번호를 설정해 주세요.</p>
      <p><a href="${url}" style="display:inline-block;padding:12px 24px;background:#1a73e8;color:#fff;text-decoration:none;border-radius:4px;">비밀번호 재설정하기</a></p>
      <p>링크가 작동하지 않으면 아래 URL을 브라우저에 직접 입력해 주세요:<br>${url}</p>
      <p>이 링크는 30분 동안 유효합니다. 본인이 요청하지 않은 경우 이 이메일을 무시하세요.</p>
    `,
  });
}
