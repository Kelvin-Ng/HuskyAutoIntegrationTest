# HuskyAutoIntegrationTest

A small script for automatically running integration tests automatically for Husky / H4 / FlexPS. Emails will be sent to the specified addresses when errors are detected in the tests. Currently, it does **not** check the output of the tests. It only checks whether the tests timeout or exit with non-zero return code.

## Usage

`./run.sh <path to machine list> <path to cmd_timeout_extra_config_list file> <path to base conf> <base dir of running> <path to master executable file> <log output dir> <tmp file dir> <path email list>`

### Machine list

A list of machine to run on. For the use of `pssh`.

### cmd\_timeout\_extra\_config\_list

A file with many line. Each line is the specification of a test. The format of each line is:
`<cmd> <timeout> <extra conf (optional)>`

Each extra conf includes the configuration specific to the corresponding test.

### Base conf

The configuration common to all tests.

### Base dir

The dir that the script will `cd` to when running the commands on each machine.

### Tmp file dir

The dir for storing temporary files. It should be accessible from all machines.

### Email list

A list of email addresses to send to when errors occur during testing.

## Example

`list.txt` includes specification for three examples of Husky. `page_rank.conf` includes the extra conf specific to the PageRank example.

Edit `email_list.txt` before running.
