# Sourced by bash in CI through BASH_ENV (see .github/workflows/ci.yml).
#
# Copies a step's output to a file and, if the step fails, publishes the last
# lines as a GitHub annotation, so the reason is readable on the run's summary
# page without downloading logs. Does nothing outside GitHub Actions.
if [ -n "${GITHUB_ACTIONS:-}" ] && [ -z "${CI_TRAP_ACTIVE:-}" ]; then
  export CI_TRAP_ACTIVE=1
  ci_log="$(mktemp)"
  exec > >(tee -a "$ci_log") 2>&1
  trap '_ci_status=$?
    if [ "$_ci_status" -ne 0 ]; then
      sleep 1
      _ci_tail="$(tail -n 40 "$ci_log" | tr -d "\r" | sed "s/%/%25/g" | awk "{printf \"%s%%0A\", \$0}")"
      echo "::error title=Step failed (exit $_ci_status)::${_ci_tail}"
    fi' EXIT
fi
