# ── Fish Shell ───────────────────────────────────────────────────────

if status is-interactive

  # ── Greeting ──────────────────────────────────────────────────────
  function fish_greeting
    set -l accent "$AURA_THEME_ACCENT"
    test -z "$accent"; and set accent 'd71921'
    set -l mono "$AURA_THEME_MONO"
    test -z "$mono"; and set mono false

    # Strip # and validate hex — must be exactly 6 hex chars
    set -l hex (string replace -a '#' '' $accent | string lower)
    if not string match -qr '^[0-9a-f]{6}$' "$hex"
      set hex 'd71921'
    end

    # Colors
    set -l dim '444444'
    set -l mid '666666'
    set -l light '999999'
    set -l white 'e8e8e8'

    # Gather info
    set -l os (cat /etc/os-release 2>/dev/null | grep "^PRETTY_NAME" | cut -d'"' -f2)
    set -l host (cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "Unknown")
    set -l kernel (uname -r)
    set -l wm "Hyprland"
    set -l cpu (lscpu 2>/dev/null | grep "Model name" | sed 's/Model name:\s*//' | string trim)
    set -l mem_used (free -m 2>/dev/null | awk '/Mem:/ {print $3}')
    set -l mem_total (free -m 2>/dev/null | awk '/Mem:/ {print $2}')
    set -l mem "$mem_used/$mem_total MiB"
    set -l uptime (uptime -p 2>/dev/null | sed 's/up //' | string replace -a ' days' 'd' | string replace -a ' day' 'd' | string replace -a ' hours' 'h' | string replace -a ' hour' 'h' | string replace -a ' minutes' 'm' | string replace -a ' minute' 'm')
    set -l pkgs (pacman -Q 2>/dev/null | wc -l | string trim)
    set -l shell_ver $FISH_VERSION

    echo

    # Info rows with alternating accent
    function _row --argument-names label value hex mono idx
      set -l dim '444444'
      set -l mid '666666'
      set -l light '999999'
      set -l white 'e8e8e8'

      echo -n '  '
      if test "$mono" = "true"
        set_color $mid
      else if test (math "$idx % 2") -eq 1
        set_color $hex
      else
        set_color $dim
      end
      echo -n '│ '
      printf '%-8s' "$label"
      set_color $light
      echo -n ' │ '
      set_color $white
      echo "$value"
      set_color normal
    end

    _row 'os' "$os" $hex $mono 1
    _row 'host' "$host" $hex $mono 2
    _row 'kernel' "$kernel" $hex $mono 3
    _row 'wm' "$wm" $hex $mono 4
    _row 'shell' "fish $shell_ver" $hex $mono 5
    _row 'cpu' "$cpu" $hex $mono 6
    _row 'memory' "$mem" $hex $mono 7
    _row 'pkgs' "$pkgs" $hex $mono 8
    _row 'uptime' "$uptime" $hex $mono 9

    echo
  end

  # ── Prompt ────────────────────────────────────────────────────────
  function fish_prompt
    set -l last_status $status
    set -l accent "$AURA_THEME_ACCENT"
    test -z "$accent"; and set accent 'd71921'
    set -l mono "$AURA_THEME_MONO"
    test -z "$mono"; and set mono false
    set -l hex (string replace -a '#' '' $accent | string lower)
    if not string match -qr '^[0-9a-f]{6}$' "$hex"
      set hex 'd71921'
    end

    set -l dim '444444'
    set -l mid '666666'
    set -l white 'e8e8e8'

    # Exit status — use named colors, not raw status codes
    if test $last_status -ne 0
      set_color red
      echo -n ' ✗ '
      set_color normal
    else
      if test "$mono" = "true"
        set_color $mid
      else
        set_color $hex
      end
      echo -n ' ○ '
      set_color normal
    end

    # User@Host
    set_color $dim
    echo -n (whoami)
    if test "$mono" = "true"
      set_color $mid
    else
      set_color $hex
    end
    echo -n '@'
    set_color $dim
    echo -n (hostname -s)
    set_color normal

    # Separator
    set_color $dim
    echo -n ' · '
    set_color normal

    # Directory
    set_color $white
    echo -n (prompt_pwd)
    set_color normal

    # Git branch
    if set -l branch (git branch --show-current 2>/dev/null)
      set_color $dim
      echo -n ' '
      if test "$mono" = "true"
        set_color $mid
      else
        set_color $hex
      end
      echo -n "⌥ $branch"
      set_color normal
    end

    # Prompt end
    set_color $dim
    echo -n ' ▸ '
    set_color normal
  end

  # ── Right prompt ──────────────────────────────────────────────────
  function fish_right_prompt
    set -l dim '444444'
    set_color $dim
    echo -n (date '+%H:%M')
    set_color normal
  end

  if not set -q AURA_THEME_ACCENT
    set -g fish_color_normal 'e8e8e8'
    set -g fish_color_command 'e8e8e8'
    set -g fish_color_keyword 'd71921'
    set -g fish_color_quote '555555'
    set -g fish_color_redirection '888888'
    set -g fish_color_end '555555'
    set -g fish_color_error 'd71921'
    set -g fish_color_param 'cccccc'
    set -g fish_color_comment '444444'
    set -g fish_color_match '222222'
    set -g fish_color_selection '000000' 'e8e8e8'

    set -g fish_pager_color_progress '555555'
    set -g fish_pager_color_background '000000'
    set -g fish_pager_color_prefix '555555'
    set -g fish_pager_color_completion '888888'
    set -g fish_pager_color_description '444444'
  end

  # ── Aliases ───────────────────────────────────────────────────────
  alias ls 'ls --color=auto'
  alias ll 'ls -la'
  alias la 'ls -A'
  alias l 'ls -CF'
  alias grep 'grep --color=auto'
  alias .. 'cd ..'
  alias ... 'cd ../..'
  alias .... 'cd ../../..'

  # ── Variables ─────────────────────────────────────────────────────
  set -gx EDITOR 'nvim'
  set -gx VISUAL 'nvim'

  # ── Abbreviations ─────────────────────────────────────────────────
  abbr -a gs git status
  abbr -a ga git add
  abbr -a gc git commit
  abbr -a gp git push
  abbr -a gl git log --oneline -10
  abbr -a gd git diff
  abbr -a gco git checkout
  abbr -a gbr git branch

  abbr -a c cargo
  abbr -a m make
  abbr -a n nvim
  abbr -a t tmux

end
