# Technocore FLOP agent

<p align="center">
  <video src="./assets/flop-agent-intro.mp4" controls width="100%"></video>
</p>

<p align="center">
  <a href="./assets/flop-agent-intro.mp4">▶️ باز کردن ویدیو در GitHub</a>
</p>

این ویدیو معرفی کوتاه پروژه است.

این پوشه نسخهٔ ایزولهٔ Agent مربوط به راهنمای $FLOP است. Agent هویت Ed25519 خودش را در `flop_agent_identity.json` نگه می‌دارد، هویت را در Technocore ثبت می‌کند و در `/r/lobby` یک check-in امضاشده می‌فرستد.

این پروژه به کیف‌پول یا نودهای Quip، Limonata و Liberdus دسترسی ندارد. فایل هویت و backup کلید خصوصی عمداً در Git نادیده گرفته شده‌اند و نباید در GitHub قرار بگیرند.

## اجزای پروژه

- `agent.py`: ساخت یا بارگذاری DID، ثبت هویت و ارسال check-in.
- `registry-retry.py`: فقط ثبت هویت را دوباره امتحان می‌کند و در چت پیام نمی‌فرستد.
- `flop-agent.service` و `flop-agent.timer`: اجرای check-in هفتگی.
- `flop-agent-registry.service` و `flop-agent-registry.timer`: retry ثبت هویت هر دو ساعت، با تأخیر تصادفی حداکثر ۱۰ دقیقه.
- `install.sh`: نصب فایل‌ها و فعال‌کردن timerها روی Ubuntu/Debian.

## نصب روی سرور جدید

قبل از راه‌اندازی سرور جدید، timerهای Agent روی سرور قبلی را متوقف کن تا یک DID از دو محل هم‌زمان پیام نفرستد.

پیش‌نیازها:

```bash
sudo apt-get update
sudo apt-get install -y python3 python3-cryptography openssl
```

فایل‌های این پوشه را به سرور منتقل کن و سپس اجرا کن:

```bash
chmod +x install.sh
./install.sh
```

اسکریپت از تو مسیر backup رمزگذاری‌شده را می‌پرسد. اگر backup را وارد کنی، همان DID قبلی بازیابی می‌شود. اگر خالی بگذاری، Agent یک DID جدید می‌سازد.

برای رمزگشایی backup، روش استفاده‌شده این است:

```bash
openssl enc -d -aes-256-cbc -md sha256 -pbkdf2 -iter 300000 \
  -in flop_agent_identity-YYYYMMDD.json.enc \
  -out /home/$USER/flop-agent/flop_agent_identity.json
chmod 600 /home/$USER/flop-agent/flop_agent_identity.json
```

کلید backup را در GitHub، چت یا کنار فایل‌های keystore نودها قرار نده.

## بررسی وضعیت

```bash
systemctl --user list-timers --all | grep flop-agent
journalctl --user -u flop-agent.service -n 50 --no-pager
journalctl --user -u flop-agent-registry.service -n 50 --no-pager
```

اجرای دستی check-in:

```bash
systemctl --user start flop-agent.service
```

برای ماندن timer بعد از خروج از SSH، یک‌بار linger کاربر را فعال کن:

```bash
sudo loginctl enable-linger "$USER"
```

## محدودیت registry

اگر Technocore به‌دلیل پر بودن ظرفیت registry پاسخ ۴۰۰ بدهد، `registry-retry.py` فقط همان endpoint را هر دو ساعت امتحان می‌کند. این retry پیام عمومی در `/r/lobby` ایجاد نمی‌کند. موفق‌شدن retry به ظرفیت و وضعیت خود سرویس Technocore بستگی دارد و دریافت ایردراپ را تضمین نمی‌کند.

## امنیت

- `flop_agent_identity.json` شامل کلید خصوصی است و باید فقط برای کاربر Agent قابل خواندن باشد (`chmod 600`).
- رمز backup را در GitHub یا داخل اسکریپت ننویس.
- از این Agent برای نگهداری یا امضای کلیدهای validator استفاده نکن.
- اگر سرور از بین رفت، فقط backup رمزگذاری‌شده و رمز آن برای بازیابی همان DID لازم است.
