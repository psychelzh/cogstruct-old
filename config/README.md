# Configurations of response metric checking

This is essentially an expansion of `dataproc.iquizoo::game_info`. They will eventually be added into the {dataproc.iquizoo} package. The added columns are used for response metric checking:

- `resp_type`: The response type. If not set, *all checks* will be skipped. Three types are classified.
  - `"required"`: only a response required, and there is no other expectation on the response times.
  - `"required_easy"`: a relative short response time is expected (in some sense, easy to judge) and a response is required.
  - `"required_hard"`: a long response time (in some sense, *long* also indicates hard to predict) is expected and a response is required.
  - `"optional"`: responses are not required.
- `name_acc`: The column name of accuray in the original data. If not set, the accuracy is not available and *count of correct responses checking* is skipped. There are two special types, and all set as capital case. `"CALCULATED"` means accuaracy can be calculated from other data columns, and `"SEPARATED"` means there are separate correctness and error columns.
- `crit_acc`: The criterion of correct for accuracy.
  - If set as a *positive number*, then the values in `name_acc` must be no larger than it to be correct (and then correct is recoded to `1` and incorrect `0`).
  - If set as `0`, then the value in `name_acc` is so coded that `0` means error, `1` means correct, and any other values (e.g., `-1`, `99`, `NA`) are treated as no response.
  - If set as `-1`, `0` means no response and there is no error.
- `chance_acc`: The chance level of accuracy.
- `duration`: The maximal lasting time for current game (in minutes). If set to 0, there is no fixed duration because it is adaptive or ended by number of trials.
- `iti`: The inter trial interval (in seconds).
- `filter`: The original data of some games need to be filtered before checking.

There are two major checking. Illustrated as follows.

## Count of correct responses checking

This check will remove subjects based on the count of correct responses.

- When `chance_acc` is not `0`: A binomial distribution (parameter $n$: the total number of trials, and parameter $p$: the chance level of accuracy) will be used to determine the criterion of the minimal number of correct responses.
- When `chance_acc` is `0`: Setting chance level to `0` means the chance level is not fixed or very hard to determine. Therefore, there is no theoretical criterion based on probability theory. Currently, there will be ***no checking*** of count of correct responses for this type. <!-- TODO: Try to guess a minimal chance level? -->

## Response rate checking

When `resp_type` is set as `"required*"`, a response rate checking is performed. There are two checking approaches:

- Firstly, the minimal response rate is set at ***80%***. This is done for any circumstances when the response rate can be directly gained from the `name_acc`. At first thought, one might argue this is not suitable for those with a fixed non-zero duration, or at least unnecessary. It turns out that there is a time limitation for trials of some games with a fixed duration, so expanding this check to all that a response rate can be directly gained will be okay and necessary.
- When `duration` is not set as `0`: response rate can by determined by the total number of trials committed.
  - `"required_easy"`: For its relative easiness, the mean reation time is set at the range of $\left[0.3, 3\right]$ seconds.
  - `"required_hard"`: For its relative hardness, the mean reation time is set at the range of $\left[2, \infty\right)$ seconds, i.e., only a minimal mean reaction time of 2 seconds is ensured.