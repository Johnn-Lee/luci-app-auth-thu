/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Copyright (C) 2025 Shuqiao Zhang
 */

'use strict';
'require form';
'require fs';
'require poll';
'require rpc';
'require uci';
'require view';

const callServiceList = rpc.declare({
	object: 'service',
	method: 'list',
	params: ['name'],
	expect: { '': {} }
});

async function getStatus() {
	const status = {
		isRunning: false,
		version: 'Unknown'
	};

	// Check if service is running
	const res = await callServiceList('goauthing');
	try {
		status.isRunning = res['goauthing']['instances']['instance1']['running'];
	} catch (e) {
		// Service not running or not found
	}

	// Get version information
	try {
		const versionRes = await fs.exec("/usr/bin/goauthing", ["--version"]);
		if (versionRes.stdout) {
			status.version = versionRes.stdout.trim();
		}
	} catch (e) {
		status.version = 'Not installed';
	}

	return status;
}

function renderStatus(isRunning) {
	const spanTemp = '<em><span style="color:%s"><strong>%s %s</strong></span></em>';
	let renderHTML;
	if (isRunning) {
		renderHTML = String.format(spanTemp, 'green', _('Auth THU'), _('RUNNING'));
	} else {
		renderHTML = String.format(spanTemp, 'red', _('Auth THU'), _('NOT RUNNING'));
	}

	return renderHTML;
}

async function getLatestVersion() {
	try {
		const result = await fs.exec("/usr/bin/wget", ["-qO-", "https://api.github.com/repos/z4yx/GoAuthing/releases/latest"]);
		if (result.code === 0 && result.stdout) {
			const data = JSON.parse(result.stdout);
			return data.tag_name;
		}
	} catch (e) {
		console.log('Failed to get latest version:', e);
	}
	return null;
}

async function detectArch() {
	try {
		const result = await fs.exec("/bin/uname", ["-m"]);
		if (result.code === 0 && result.stdout) {
			const uname = result.stdout.trim();
			// Map uname output to GoAuthing arch names
			const archMap = {
				'armv7l': 'arm',
				'aarch64': 'arm64',
				'armv5tel': 'armv5',
				'armv6l': 'armv6',
				'loongarch64': 'loong64',
				'mips': 'mipsbe',
				'mipsel': 'mipsle',
				'ppc64le': 'ppc64le',
				'riscv64': 'riscv64',
				'x86_64': 'x86_64'
			};
			return archMap[uname] || 'x86_64'; // default fallback
		}
	} catch (e) {
		console.log('Failed to detect arch:', e);
	}
	return 'x86_64'; // default fallback
}

async function generateDownloadUrl() {
	const version = await getLatestVersion();
	const arch = await detectArch();

	if (!version) {
		alert(_('Failed to get latest version from GitHub'));
		return `https://mirrors.tuna.tsinghua.edu.cn/github-release/z4yx/GoAuthing/LatestRelease/auth-thu.linux.${arch}`;
	}

	return `https://mirrors.tuna.tsinghua.edu.cn/github-release/z4yx/GoAuthing/LatestRelease/auth-thu.linux.${arch}
https://github.com/z4yx/GoAuthing/releases/download/${version}/auth-thu.linux.${arch}`;
}

async function downloadCore(downloadUrls) {
	downloadUrls = downloadUrls || '';

	// If using template, generate the actual URL
	if (downloadUrls.includes('${version}') || downloadUrls.includes('${arch}')) {
		const version = downloadUrls.includes('${version}') ? await getLatestVersion() : '';
		const arch = downloadUrls.includes('${arch}') ? await detectArch() : '';

		if (downloadUrls.includes('${version}') && !version) {
			alert(_('Failed to get latest version from GitHub'));
			return;
		}

		downloadUrls = downloadUrls
			.replace(/\$\{version\}/g, version)
			.replace(/\$\{arch\}/g, arch);
	}

	const urls = downloadUrls.split('\n').map(url => url.trim()).filter(Boolean);

	if (urls.length === 0) {
		alert(_('Please configure download URLs first'));
		return;
	}

	try {
		const result = await fs.exec('/usr/libexec/auth-thu-download', urls);
		if (result.code !== 0)
			throw new Error(result.stderr || _('Core download failed'));
		alert(_('Core downloaded successfully'));
	} catch (e) {
		alert(_('Core download failed') + ': ' + e.message);
	}
}

return view.extend({
	load() {
		return Promise.all([
			uci.load('goauthing'),
			getStatus()
		]);
	},

	render(data) {
		let m, s, o, downloadUrlsOption;

		m = new form.Map('goauthing', _('Auth THU'), _('Auth THU is a network authentication client for campus networks.'));

		s = m.section(form.TypedSection);
		s.anonymous = true;
		s.render = function() {
			poll.add(async function() {
				const res = await getStatus();
				const service_view = document.getElementById("service_status");
				const version_view = document.getElementById("version_display");
				if (service_view) service_view.innerHTML = renderStatus(res.isRunning);
				if (version_view) version_view.textContent = res.version;
			});

			return E('div', { class: 'cbi-section', id: 'status_bar' }, [
				E('p', { id: 'service_status' }, _('Collecting data ...'))
			]);
		}

		s = m.section(form.NamedSection, 'config', 'goauthing');

		o = s.option(form.Flag, 'enabled', _('Enable'));
		o.default = o.disabled;
		o.rmempty = false;

		o = s.option(form.Value, 'username', _('Username'), _('Enter your authentication username.'));
		o.default = '';
		o.rmempty = false;

		o = s.option(form.Value, 'password', _('Password'), _('Enter your authentication password.'));
		o.password = true;
		o.default = '';
		o.rmempty = false;

		o = s.option(form.DummyValue, 'core_version', _('Core Version'));
		o.renderWidget = function(section_id, option_id) {
			return E('div', { 'id': 'version_display' }, _('Collecting data ...'));
		};

		o = s.option(form.Button, 'download_core', _('Download Core'), _('Download the latest GoAuthing core from configured URLs.'));
		o.inputtitle = _('Download');
		o.onclick = async function() {
			if (confirm(_('Are you sure you want to download the core? This will replace the current version.'))) {
				await downloadCore(downloadUrlsOption.formvalue('config') ?? downloadUrlsOption.default);
			}
		};

		o = s.option(form.Button, 'auto_generate_url', _('Auto Generate URL'), _('Generate download URL automatically using latest version and detected architecture.'));
		o.inputtitle = _('Generate');
		o.onclick = async function() {
			const url = await generateDownloadUrl();
			if (url) {
				const textarea = document.getElementById('widget.cbid.goauthing.config.download_urls');
				if (textarea) {
					textarea.value = url;
					textarea.dispatchEvent(new Event('input', { bubbles: true }));
				}
			}
		};

		o = s.option(form.TextValue, 'download_urls', _('Core Download URLs'),
			_('Enter download URLs, one per line. The system will try each URL in order until download succeeds.<br>' +
				'Template variables supported: <code>${version}</code> (latest from GitHub), <code>${arch}</code> (auto-detected)<br>'));
		o.rows = 5;
		o.default = 'https://mirrors.tuna.tsinghua.edu.cn/github-release/z4yx/GoAuthing/LatestRelease/auth-thu.linux.${arch}';
		o.rmempty = true;
		downloadUrlsOption = o;
		return m.render();
	}
});
