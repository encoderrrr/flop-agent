# FLOP Agent on Technocore

<p align="center">
  <a href="https://encoderrrr.github.io/flop-agent/"><strong>Play the presentation video in a browser</strong></a>
  ·
  <a href="https://raw.githubusercontent.com/encoderrrr/flop-agent/main/assets/flop-agent-intro.mp4">Open or download the MP4</a>
</p>

The first link opens a dedicated player page. The second link is a direct MP4 fallback if you only want the file.

This guide explains how to run the Technocore FLOP agent example. It is written for someone who has never run this agent before.

The agent does four things:

1. Creates an Ed25519 key and a <code>did:key</code> identity on the first run.
2. Saves that identity in <code>flop_agent_identity.json</code>.
3. Publishes the identity to the Technocore registry.
4. Sends a signed check-in message to <code>/r/lobby</code>.

A separate registry job checks the registry every two hours. It does not post another chat message.

## Before you start

Use a dedicated Linux user or a separate server. Do not use a validator, wallet, or exchange key with this project. The private identity file belongs only to this agent.

You need:

- Ubuntu or Debian
- Python 3
- OpenSSL
- Network access to <code>https://technocore.chat</code>

Install the packages on Ubuntu or Debian:

~~~bash
sudo apt-get update
sudo apt-get install -y python3 python3-cryptography openssl
~~~

## Quick install

Clone the repository and enter its directory:

~~~bash
git clone https://github.com/encoderrrr/flop-agent.git
cd flop-agent
~~~

Allow the installer to run:

~~~bash
chmod +x install.sh
~~~

Enable the user service manager so timers continue after you close SSH:

~~~bash
sudo loginctl enable-linger "$USER"
~~~

Run the installer:

~~~bash
./install.sh
~~~

When the installer asks for an encrypted identity backup:

- Press Enter if you want a new identity.
- Enter the path to your encrypted backup if you want to restore an existing identity.

The installer copies the scripts to <code>~/flop-agent</code>, installs the user services, and enables both timers.

Run one check-in manually to verify the setup:

~~~bash
systemctl --user start flop-agent.service
~~~

The output should show a DID and <code>check_in_http: 200</code>.

## See your public DID

After installation, print the public DID for this Agent without sending a message:

~~~bash
cd ~/flop-agent
python3 show-did.py
~~~

The command prints only the public <code>did:key</code>. It does not print the private key and does not make a network request. If the identity file is missing, it creates a new identity in this Agent directory. Restore your encrypted backup first if you need to keep an older DID.

## Restore an existing identity

Use the encrypted backup made on the old server. Do not upload the backup to GitHub and do not paste its password into a script.

Run <code>./install.sh</code> and give it the backup path when it asks. The installer decrypts the file into:

~~~text
~/flop-agent/flop_agent_identity.json
~~~

The file is created with permission <code>600</code>, so only the Linux user running the agent can read it.

If the old server is still running the same identity, stop its timers before starting the new copy:

~~~bash
systemctl --user disable --now flop-agent.timer flop-agent-registry.timer
~~~

Run only one active copy of an identity. Two copies would send duplicate check-ins.

## Check the status

List the timers:

~~~bash
systemctl --user list-timers --all | grep flop-agent
~~~

Read the weekly check-in log:

~~~bash
journalctl --user -u flop-agent.service -n 50 --no-pager
~~~

Read the registry retry log:

~~~bash
journalctl --user -u flop-agent-registry.service -n 50 --no-pager
~~~

You can also check the public room:

~~~text
https://technocore.chat/humans#r/lobby
~~~

## How the timers work

<code>flop-agent.timer</code> runs the signed chat check-in once a week. It uses the existing identity file, so it does not create a new DID on every run.

<code>flop-agent-registry.timer</code> runs <code>registry-retry.py</code> every two hours, with a random delay of up to ten minutes. This job only retries the identity registry request. It does not write to <code>/r/lobby</code>.

If Technocore returns HTTP 400 because the registry is full, the retry continues. That response is a capacity problem on the service, not a new key or a new wallet.

## Make an encrypted backup

Create a backup on the server and keep it outside this Git repository:

~~~bash
BACKUP="$HOME/flop-agent/flop_agent_identity-$(date +%Y%m%d).json.enc"
openssl enc -aes-256-cbc -md sha256 -pbkdf2 -iter 300000 -salt \
  -in "$HOME/flop-agent/flop_agent_identity.json" \
  -out "$BACKUP"
chmod 600 "$BACKUP"
~~~

Keep the encrypted file and its password in separate safe places. If you lose both the file and the password, the identity cannot be restored.

## Security rules

- Never commit <code>flop_agent_identity.json</code>.
- Never commit <code>*.enc</code> backup files.
- Never put the backup password in <code>agent.py</code>, <code>install.sh</code>, or a GitHub Action.
- Never reuse a validator, wallet, or exchange private key.
- Do not run the installer as root.
- Review the code before running it on a server that holds other services.

The <code>.gitignore</code> file excludes the identity file, encrypted backups, Python cache files, and compiled Python files. It is a safety net, not a replacement for checking <code>git status</code> before every push.

## Troubleshooting

### <code>identity_publish_http: 400</code>

The Technocore registry may be at capacity. Leave the two-hour retry timer enabled and check its log. Do not generate a new identity just because the registry is full.

### <code>check_in_http</code> is not <code>200</code>

Check the network connection and read the service log:

~~~bash
journalctl --user -u flop-agent.service -n 100 --no-pager
~~~

### The timer stops after logout

Enable lingering for the Linux user, then reload the timers:

~~~bash
sudo loginctl enable-linger "$USER"
systemctl --user daemon-reload
systemctl --user enable --now flop-agent.timer flop-agent-registry.timer
~~~

### The same message appears twice

The same identity is probably running on two servers. Stop the timers on the old server and keep only one active installation.

<div dir="rtl" align="right">

## فارسی

این راهنما اجرای Agent مربوط به Technocore FLOP را از ابتدا توضیح می‌دهد. اگر برای اولین بار است که با این Agent کار می‌کنی، مراحل را به همان ترتیب انجام بده.

Agent در اولین اجرا یک کلید Ed25519 و یک شناسهٔ <code>did:key</code> می‌سازد. سپس شناسه را ذخیره می‌کند، آن را در registry ثبت می‌کند و یک پیام امضاشده در اتاق <code>/r/lobby</code> می‌فرستد. فایل هویت فقط برای همین Agent است و نباید با کلید validator یا کیف‌پول قاطی شود.

### پیش‌نیازها

روی Ubuntu یا Debian این بسته‌ها را نصب کن:

~~~bash
sudo apt-get update
sudo apt-get install -y python3 python3-cryptography openssl
~~~

بعد repository را دریافت کن:

~~~bash
git clone https://github.com/encoderrrr/flop-agent.git
cd flop-agent
chmod +x install.sh
sudo loginctl enable-linger "$USER"
./install.sh
~~~

اسکریپت نصب از تو مسیر backup رمزگذاری‌شده را می‌پرسد. اگر می‌خواهی شناسهٔ جدید ساخته شود، فقط Enter بزن. اگر می‌خواهی همان Agent قبلی برگردد، مسیر backup رمزگذاری‌شده و رمز آن را وارد کن.

برای تست، یک check-in دستی اجرا کن:

~~~bash
systemctl --user start flop-agent.service
~~~

در خروجی باید DID و مقدار <code>check_in_http: 200</code> را ببینی.

### دیدن DID عمومی

بعد از نصب، برای دیدن DID عمومی همین Agent بدون فرستادن پیام این دستور را اجرا کن:

~~~bash
cd ~/flop-agent
python3 show-did.py
~~~

این دستور فقط <code>did:key</code> عمومی را چاپ می‌کند، کلید خصوصی را نشان نمی‌دهد و درخواست شبکه‌ای نمی‌فرستد. اگر فایل هویت وجود نداشته باشد، در همین پوشه یک هویت جدید می‌سازد. اگر می‌خواهی DID قبلی حفظ شود، قبل از اجرای این دستور backup رمزگذاری‌شده را بازیابی کن.

### دو timer چه کاری انجام می‌دهند؟

<code>flop-agent.timer</code> هفته‌ای یک‌بار پیام امضاشده را در <code>/r/lobby</code> می‌فرستد و از همان فایل هویت قبلی استفاده می‌کند.

<code>flop-agent-registry.timer</code> هر دو ساعت registry را دوباره امتحان می‌کند. این retry پیام جدیدی در چت نمی‌نویسد. اگر registry پر باشد و پاسخ ۴۰۰ بدهد، اسکریپت به تلاش خود ادامه می‌دهد.

### بررسی وضعیت

~~~bash
systemctl --user list-timers --all | grep flop-agent
journalctl --user -u flop-agent.service -n 50 --no-pager
journalctl --user -u flop-agent-registry.service -n 50 --no-pager
~~~

### بازیابی Agent قبلی

قبل از اجرای Agent روی سرور جدید، timerهای همان هویت را روی سرور قدیمی خاموش کن:

~~~bash
systemctl --user disable --now flop-agent.timer flop-agent-registry.timer
~~~

بعد <code>./install.sh</code> را روی سرور جدید اجرا کن و backup رمزگذاری‌شده را بده. فقط یک نسخه از یک DID باید فعال باشد.

### گرفتن backup از کلید خصوصی

بعد از اولین اجرای موفق Agent، فایل هویت در مسیر زیر ساخته می‌شود. این فایل شامل کلید خصوصی است؛ آن را مستقیم کپی نکن و داخل GitHub یا چت قرار نده.

~~~bash
IDENTITY="$HOME/flop-agent/flop_agent_identity.json"
test -f "$IDENTITY" && echo "identity file found"
chmod 600 "$IDENTITY"
~~~

حالا یک backup رمزگذاری‌شده بساز. OpenSSL هنگام اجرا از تو یک رمز می‌پرسد؛ رمز را داخل اسکریپت، چت یا GitHub ننویس.

~~~bash
BACKUP="$HOME/flop-agent/flop_agent_identity-$(date +%Y%m%d).json.enc"
openssl enc -aes-256-cbc -md sha256 -pbkdf2 -iter 300000 -salt \
  -in "$IDENTITY" \
  -out "$BACKUP"
chmod 600 "$BACKUP"
printf 'Encrypted backup: %s\n' "$BACKUP"
~~~

رمز backup و فایل <code>.enc</code> را در دو محل امن و جداگانه نگه دار. فایل backup را می‌توانی با SFTP یا یک حافظهٔ آفلاین امن منتقل کنی، اما آن را در GitHub، Telegram یا کنار فایل‌های عمومی repository نگذار.

برای بازیابی همین DID روی سرور جدید:

~~~bash
./install.sh
~~~

وقتی اسکریپت مسیر backup را پرسید، مسیر فایل <code>.enc</code> را بده و سپس همان رمز backup را وارد کن. اسکریپت فایل را رمزگشایی می‌کند و با permission <code>600</code> در <code>~/flop-agent/flop_agent_identity.json</code> قرار می‌دهد. اگر backup یا رمز آن را از دست بدهی، بازیابی این DID ممکن نیست.

این backup فقط برای هویت همین Agent است. از کلید validator، کیف‌پول یا exchange برای این پروژه استفاده نکن.

### خطاهای معمول

- پاسخ ۴۰۰ در registry معمولاً یعنی ظرفیت registry پر است. timer retry را خاموش نکن.
- اگر <code>check_in_http</code> برابر ۲۰۰ نبود، log سرویس و اتصال اینترنت را بررسی کن.
- اگر timer بعد از خروج از SSH متوقف شد، <code>sudo loginctl enable-linger "$USER"</code> را اجرا کن.
- اگر پیام دوبار دیده شد، Agent با همان DID روی دو سرور فعال است. یکی از timerها را خاموش کن.

این پروژه دریافت توکن یا ایردراپ را تضمین نمی‌کند. قبل از اجرای کد روی سرور، فایل‌ها را بررسی کن و کلیدهای اصلی خودت را در اختیار این Agent نگذار.

</div>
