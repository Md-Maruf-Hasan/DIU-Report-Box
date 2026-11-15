import axios from "axios";

export interface SmsSendResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface SmsProvider {
  sendSms(phone: string, message: string): Promise<SmsSendResult>;
}

export class MockSmsProvider implements SmsProvider {
  async sendSms(phone: string, message: string): Promise<SmsSendResult> {
    console.log(`[Mock SMS] Sending to ${phone}: "${message}" (length: ${message.length})`);
    return {
      success: true,
      messageId: `mock-msg-${Date.now()}`,
    };
  }
}

export class SslWirelessSmsProvider implements SmsProvider {
  private apiToken = process.env.SMS_API_KEY || "";
  private sid = process.env.SMS_SID || "";
  private domain = process.env.SMS_DOMAIN || "https://smsplus.sslwireless.com";

  async sendSms(phone: string, message: string): Promise<SmsSendResult> {
    try {
      const formattedPhone = phone.startsWith("88") ? phone : `88${phone}`;
      const response = await axios.post(`${this.domain}/api/v3/send-sms`, {
        api_token: this.apiToken,
        sid: this.sid,
        msisdn: formattedPhone,
        sms: message,
        csms_id: `ref_${Date.now()}`,
      }, { timeout: 10000 });

      if (response.data && (response.data.status === "SUCCESS" || response.data.status_code === 200)) {
        return { success: true, messageId: response.data.smsinfo?.[0]?.sms_id || "ssl-success" };
      }
      return { success: false, error: response.data.error_message || "SSL Wireless error" };
    } catch (err: any) {
      return { success: false, error: err.message || "Network error sending SMS" };
    }
  }
}

export class BulkSmsBdProvider implements SmsProvider {
  private apiKey = process.env.SMS_API_KEY || "";
  private senderId = process.env.SMS_SENDER_ID || "";

  async sendSms(phone: string, message: string): Promise<SmsSendResult> {
    try {
      const response = await axios.post("http://bulksmsbd.net/api/smsapi", {
        api_key: this.apiKey,
        type: "text",
        number: phone,
        senderid: this.senderId,
        message: message,
      }, { timeout: 10000 });

      if (response.data && response.data.response_code === 202) {
        return { success: true, messageId: response.data.success_message };
      }
      return { success: false, error: response.data?.error_message || "BulkSMSBD error" };
    } catch (err: any) {
      return { success: false, error: err.message || "Network error sending SMS" };
    }
  }
}

export class AlphaSmsProvider implements SmsProvider {
  private apiKey = process.env.SMS_API_KEY || "";

  async sendSms(phone: string, message: string): Promise<SmsSendResult> {
    try {
      const response = await axios.post("https://api.sms.net.bd/sendsms", {
        api_key: this.apiKey,
        msg: message,
        to: phone,
      }, { timeout: 10000 });

      if (response.data && response.data.error === 0) {
        return { success: true, messageId: String(response.data.request_id) };
      }
      return { success: false, error: response.data?.msg || "Alpha SMS error" };
    } catch (err: any) {
      return { success: false, error: err.message || "Network error sending SMS" };
    }
  }
}

export function getSmsProvider(): SmsProvider {
  const providerType = process.env.SMS_GATEWAY_PROVIDER?.toLowerCase() || "mock";
  switch (providerType) {
    case "ssl_wireless":
      return new SslWirelessSmsProvider();
    case "bulksmsbd":
      return new BulkSmsBdProvider();
    case "alpha_sms":
      return new AlphaSmsProvider();
    default:
      return new MockSmsProvider();
  }
}

export function formatReportSms(params: {
  deptCode: string;
  roomNo: string;
  category: string;
  description: string;
  refNo: string;
}): string {
  // Format: DIU Report: SWE Room 703 - Computer/IT. PC#4 not turning on. Ref: R-1042
  // Max GSM characters: 160
  const prefix = `DIU Report: ${params.deptCode} Room ${params.roomNo} - ${params.category}. `;
  const suffix = ` Ref: ${params.refNo}`;
  const availableDescLen = 160 - prefix.length - suffix.length;

  let desc = params.description.replace(/[\r\n]+/g, " ").trim();
  if (desc.length > availableDescLen) {
    desc = desc.substring(0, Math.max(0, availableDescLen - 3)) + "...";
  }

  const message = `${prefix}${desc}.${suffix}`;
  return message;
}
