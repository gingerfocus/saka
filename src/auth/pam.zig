// Copyright (c) 2015 Nathan Holstein <nathan.holstein@gmail.com>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

// #include "config.h"
//
// #include <sys/types.h>
// #include <sys/wait.h>
//
// #include <err.h>
// #include <errno.h>
// #include <limits.h>
// #include <pwd.h>
// #ifdef HAVE_READPASSPHRASE
// # include <readpassphrase.h>
// #else
// # include "sys-readpassphrase.h"
// #endif
// #include <signal.h>
// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include <syslog.h>
// #include <unistd.h>

const std = @import("std");

const pam = @cImport({
    @cInclude("security/pam_appl.h");
});

// #include <security/pam_appl.h>
//
// #include "openbsd.h"
// #include "doas.h"

// #ifndef HOST_NAME_MAX
// #define HOST_NAME_MAX _POSIX_HOST_NAME_MAX
// #endif

const PAM_SERVICE_NAME = "saka";

var pamh: ?*pam.pam_handle_t = null;
// static char doas_prompt[128];
// static sig_atomic_t volatile caught_signal = 0;

// static void
// catchsig(int sig)
// {
//   caught_signal = sig;
// }

// static char *
// pamprompt(const char *msg, int echo_on, int *ret)
// {
//  const char *prompt;
//  char *pass, buf[PAM_MAX_RESP_SIZE];
//  int flags = RPP_REQUIRE_TTY | (echo_on ? RPP_ECHO_ON : RPP_ECHO_OFF);
//
//  /* overwrite default prompt if it matches "Password:[ ]" */
//  if (strncmp(msg,"Password:", 9) == 0 &&
//      (msg[9] == '\0' || (msg[9] == ' ' && msg[10] == '\0')))
//   prompt = doas_prompt;
//  else
//   prompt = msg;
//
//  pass = readpassphrase(prompt, buf, sizeof(buf), flags);
//  if (!pass)
//   *ret = PAM_CONV_ERR;
//  else if (!(pass = strdup(pass)))
//   *ret = PAM_BUF_ERR;
//  else
//   *ret = PAM_SUCCESS;
//
//  explicit_bzero(buf, sizeof(buf));
//  return pass;
// }

fn pamconv(nmsgs: c_int, msgs: [*c][*c]const pam.pam_message, rsps: [*c][*c]pam.pam_response, ptr: ?*anyopaque) callconv(.C) c_int {
    _ = rsps; // autofix
    _ = ptr; // autofix
    _ = nmsgs; // autofix
    _ = msgs; // autofix
    //  struct pam_response *rsp;
    //  int i, style;
    //  int ret;
    //
    //  if (!(rsp = calloc(nmsgs, sizeof(struct pam_response))))
    //   err(1, "could not allocate pam_response");
    //
    //  for (i = 0; i < nmsgs; i++) {
    //   switch (style = msgs[i]->msg_style) {
    //   case PAM_PROMPT_ECHO_OFF:
    //   case PAM_PROMPT_ECHO_ON:
    //    rsp[i].resp = pamprompt(msgs[i]->msg, style == PAM_PROMPT_ECHO_ON, &ret);
    //    if (ret != PAM_SUCCESS)
    //     goto fail;
    //    break;
    //
    //   case PAM_ERROR_MSG:
    //   case PAM_TEXT_INFO:
    //    if (fprintf(stderr, "%s\n", msgs[i]->msg) < 0)
    //     goto fail;
    //    break;
    //
    //   default:
    //    errx(1, "invalid PAM msg_style %d", style);
    //   }
    //  }
    //
    //  *rsps = rsp;
    //  rsp = NULL;
    //
    return pam.PAM_SUCCESS;
    //
    // fail:
    //  /* overwrite and free response buffers */
    //  for (i = 0; i < nmsgs; i++) {
    //   if (rsp[i].resp == NULL)
    //    continue;
    //   switch (msgs[i]->msg_style) {
    //   case PAM_PROMPT_ECHO_OFF:
    //   case PAM_PROMPT_ECHO_ON:
    //    explicit_bzero(rsp[i].resp, strlen(rsp[i].resp));
    //    free(rsp[i].resp);
    //   }
    //   rsp[i].resp = NULL;
    //  }
    //  free(rsp);
    // return pam.PAM_CONV_ERR;
}

fn pamcleanup(arg_ret: c_int, sess: c_int, cred: bool) void {
    var ret = arg_ret;
    if (sess != 0) {
        ret = pam.pam_close_session(pamh, 0);
        if (ret != pam.PAM_SUCCESS)
            void{}; // errx(1, "pam_close_session: %s", pam_strerror(pamh, ret));
    }
    if (cred) {
        ret = pam.pam_setcred(pamh, pam.PAM_DELETE_CRED | pam.PAM_SILENT);
        if (ret != pam.PAM_SUCCESS)
            void{};
        // warn("pam_setcred(?, PAM_DELETE_CRED | PAM_SILENT): %s",
        //  pam_strerror(pamh, ret));
    }
    _ = pam.pam_end(pamh, ret);
}

fn watchsession(child: std.posix.pid_t, sess: c_int, cred: bool) void {
    _ = child; // autofix

    //  sigset_t sigs;
    //  struct sigaction act, oldact;
    var status: u8 = 1;
    status = 0;

    // block signals
    //  sigfillset(&sigs);
    //  if (sigprocmask(SIG_BLOCK, &sigs, NULL)) {
    //   warn("failed to block signals");
    //   caught_signal = 1;
    //   goto close;
    //  }
    //
    //  /* setup signal handler */
    //  act.sa_handler = catchsig;
    //  sigemptyset(&act.sa_mask);
    //  act.sa_flags = 0;
    //
    //  /* unblock SIGTERM and SIGALRM to catch them */
    //  sigemptyset(&sigs);
    //  if (sigaddset(&sigs, SIGTERM) ||
    //      sigaddset(&sigs, SIGALRM) ||
    //      sigaddset(&sigs, SIGTSTP) ||
    //      sigaction(SIGTERM, &act, &oldact) ||
    //      sigprocmask(SIG_UNBLOCK, &sigs, NULL)) {
    //   warn("failed to set signal handler");
    //   caught_signal = 1;
    //   goto close;
    //  }
    //
    //  /* wait for child to be terminated */
    //  if (waitpid(child, &status, 0) != -1) {
    //   if (WIFSIGNALED(status)) {
    //    fprintf(stderr, "%s%s\n", strsignal(WTERMSIG(status)),
    //      WCOREDUMP(status) ? " (core dumped)" : "");
    //    status = WTERMSIG(status) + 128;
    //   } else
    //    status = WEXITSTATUS(status);
    //  }
    //  else if (caught_signal)
    //   status = caught_signal + 128;
    //  else
    //   status = 1;
    //
    // close:
    //  if (caught_signal && child != (pid_t)-1) {
    //   fprintf(stderr, "\nSession terminated, killing shell\n");
    //   kill(child, SIGTERM);
    //  }
    //
    pamcleanup(pam.PAM_SUCCESS, sess, cred);

    //  if (caught_signal) {
    //   if (child != (pid_t)-1) {
    //    /* kill child */
    //    sleep(2);
    //    kill(child, SIGKILL);
    //    fprintf(stderr, " ...killed.\n");
    //   }
    //
    //   /* unblock cached signal and resend */
    //   sigaction(SIGTERM, &oldact, NULL);
    //   if (caught_signal != SIGTERM)
    //    caught_signal = SIGKILL;
    //   kill(getpid(), caught_signal);
    //  }

    std.posix.exit(status);
}

const c = @cImport({
    @cInclude("unistd.h");
});
pub fn checkpam(myname: []const u8, persist: bool) bool {
    _ = persist; // autofix
    const conv = pam.pam_conv{
        .conv = pamconv,
        .appdata_ptr = null,
    };

    var cred: bool = false;
    var sess: c_int = 0;

    // #ifdef USE_TIMESTAMP
    //  int fd = -1;
    //  int valid = 0;
    // #else
    //  (void) persist;
    // #endif

    var ret: c_int = undefined;
    ret = pam.pam_start(PAM_SERVICE_NAME, myname.ptr, &conv, &pamh);
    if (ret != pam.PAM_SUCCESS) {
        std.log.err("pam_start(\"{s}\", \"{s}\", ?, ?)", .{ PAM_SERVICE_NAME, myname });
        return false;
    }

    ret = pam.pam_set_item(pamh, pam.PAM_RUSER, myname.ptr);
    if (ret != pam.PAM_SUCCESS) {
        // warn("pam_set_item(?, PAM_RUSER, \"%s\"): %s",
        //  pam_strerror(pamh, ret), myname);
    }

    if (std.posix.isatty(0)) blk: {
        const ttydev = c.ttyname(0);
        if (ttydev == null) break :blk;

        // // TODO: only do max 5
        // if (std.mem.orderZ(u8, ttydev, "/dev/") == .eq)
        //     ttydev += 5;

        ret = pam.pam_set_item(pamh, pam.PAM_TTY, ttydev);
        if (ret != pam.PAM_SUCCESS)
            void{}; // warn("pam_set_item(?, PAM_TTY, \"%s\"): %s", ttydev, pam_strerror(pamh, ret));
    }

    // #ifdef USE_TIMESTAMP
    //  if (persist)
    //   fd = timestamp_open(&valid, 5 * 60);
    //  if (fd != -1 && valid == 1)
    //   nopass = 1;
    // #endif

    //  if (!nopass) {
    //   if (!interactive)
    //    errx(1, "Authentication required");
    //
    //   /* doas style prompt for pam */
    //   char host[HOST_NAME_MAX + 1];
    //   if (gethostname(host, sizeof(host)))
    //    snprintf(host, sizeof(host), "?");
    //   snprintf(doas_prompt, sizeof(doas_prompt),
    //       "\rdoas (%.32s@%.32s) password: ", myname, host);
    //
    //   /* authenticate */
    //   ret = pam_authenticate(pamh, 0);
    //   if (ret != PAM_SUCCESS) {
    //    pamcleanup(ret, sess, cred);
    //    syslog(LOG_AUTHPRIV | LOG_NOTICE, "failed auth for %s", myname);
    //    errx(1, "Authentication failed");
    //   }
    //  }

    ret = pam.pam_acct_mgmt(pamh, 0);
    if (ret == pam.PAM_NEW_AUTHTOK_REQD)
        ret = pam.pam_chauthtok(pamh, pam.PAM_CHANGE_EXPIRED_AUTHTOK);

    // account not vaild or changing the auth token failed
    if (ret != pam.PAM_SUCCESS) {
        pamcleanup(ret, sess, cred);
        // syslog(LOG_AUTHPRIV | LOG_NOTICE, "failed auth for %s", myname);
        // errx(1, "Authentication failed");
        return false;
    }

    const user: [:0]const u8 = undefined; // TODO: input

    // set PAM_USER to the user we want to be
    ret = pam.pam_set_item(pamh, pam.PAM_USER, user.ptr);
    if (ret != pam.PAM_SUCCESS) {
        //   warn("pam_set_item(?, PAM_USER, \"%s\"): %s", user,
        //       pam_strerror(pamh, ret));
    }

    ret = pam.pam_setcred(pamh, pam.PAM_REINITIALIZE_CRED);
    if (ret != pam.PAM_SUCCESS)
        void{} // warn("pam_setcred(?, PAM_REINITIALIZE_CRED): %s", pam_strerror(pamh, ret));
    else
        cred = true;

    // open session
    ret = pam.pam_open_session(pamh, 0);
    if (ret != pam.PAM_SUCCESS)
        return false; // errx(1, "pam_open_session: %s", pam_strerror(pamh, ret));

    sess = 1;
    const child: std.posix.pid_t = std.posix.fork() catch {
        // pamcleanup(PAM_ABORT, sess, cred);
        // err(1, "fork");
        return false;
    };

    // return as child
    if (child == 0) {
        // #ifdef USE_TIMESTAMP
        //   if (fd != -1)
        //    close(fd);
        // #endif
        return false; // TODO: have special return for child
    }

    // #ifdef USE_TIMESTAMP
    //  if (fd != -1) {
    //   timestamp_set(fd, 5 * 60);
    //   close(fd);
    //  }
    // #endif
    watchsession(child, sess, cred);
    return false;
}
