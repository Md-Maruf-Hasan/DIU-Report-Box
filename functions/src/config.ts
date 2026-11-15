export const CONFIG = {
  ALLOWED_EMAIL_DOMAIN: process.env.ALLOWED_EMAIL_DOMAIN || "diu.edu.bd",
  MAX_REPORTS_PER_DAY: 5,
  MIN_REPORT_DESC_LENGTH: 15,
  MAX_SMS_ATTEMPTS: 3,
  SMS_GATEWAY_PROVIDER: process.env.SMS_GATEWAY_PROVIDER || "mock", // 'mock' | 'ssl_wireless' | 'bulksmsbd' | 'alpha_sms'
};
