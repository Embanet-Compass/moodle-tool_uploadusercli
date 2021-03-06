<?php
// This file is part of Moodle - http://moodle.org/
//
// Moodle is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Moodle is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Moodle.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Output tracker.
 *
 * @package    tool_uploadusercli
 * @copyright  2015 Alexandru Elisei
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */

defined('MOODLE_INTERNAL') || die();

/**
 * Class output tracker.
 *
 * @package    tool_uploadusercli
 * @copyright  2015 Alexandru Elisei
 * @license    http://www.gnu.org/copyleft/gpl.html GNU GPL v3 or later
 */
class tool_uploadusercli_tracker {

    /**
     * Constant to output nothing.
     */
    const NO_OUTPUT = 0;

    /**
     * Constant to output plain text.
     */
    const OUTPUT_PLAIN = 1;

    /**
     * @var array columns to display.
     */
    protected $columns = array('line', 'result', 'username', 'firstname', 
                                'lastname',  'email', 'id', 'status');

    /**
     * @var int row number.
     */
    protected $rownb = 0;

    /**
     * @var int chosen output mode.
     */
    protected $outputmode;

    /**
     * @var object output buffer.
     */
    protected $buffer;

    /**
     * Constructor.
     *
     * @param int $outputmode desired output mode.
     */
    public function __construct($outputmode = self::NO_OUTPUT) {
        $this->outputmode = $outputmode;
        if ($this->outputmode === self::OUTPUT_PLAIN) {
            $this->buffer = new progress_trace_buffer(new text_progress_trace());
        }
    }

    /**
     * Output one more line.
     *
     * @param int $line line number.
     * @param bool $outcome success or not?
     * @param array $status array of statuses.
     * @param array $data extra data to display.
     * @return void
     */
    public function output($line, $outcome, $status, $data) {
        global $OUTPUT;

        if ($this->outputmode === self::NO_OUTPUT) {
            return;
        }

        if ($this->outputmode == self::OUTPUT_PLAIN) {
            $message = array(
                $line,
                $outcome ? 'OK' : 'NOK',
                isset($data['username']) ? $data['username'] : 'ERR',
                isset($data['firstname']) ? $data['firstname'] : 'ERR',
                isset($data['lastname']) ? $data['lastname'] : 'ERR',
                isset($data['email']) ? $data['email'] : 'ERR',
                isset($data['id']) ? $data['id'] : 'N/A',
            );
            $this->buffer->output(implode("\t", $message));
            if (!empty($status)) {
                foreach ($status as $st) {
                    $this->buffer->output($st, 1);
                }
            }
        }
    }

    /**
     * Start the output.
     *
     * @return void
     */
    public function start() {
        if ($this->outputmode == self::NO_OUTPUT) {
            return;
        }

        if ($this->outputmode == self::OUTPUT_PLAIN) {
            $columns = array_flip($this->columns);
            unset($columns['status']);
            $columns = array_flip($columns);
            $this->buffer->output(implode("\t", $columns));
        } 
    }

    /**
     * Output the results.
     *
     * @param int $total total users.
     * @param int $created count of users created.
     * @param int $updated count of users updated.
     * @param int $deleted count of users deleted.
     * @param int $errors count of errors.
     * @return void
     */
    public function results($total, $created, $updated, $deleted, $errors) {
        if ($this->outputmode == self::NO_OUTPUT) {
            return;
        }
        $message = array(
            "",
            get_string('userscreated', 'tool_uploadusercli') . ": $created",
            get_string('usersupdated', 'tool_uploadusercli') . ": $updated",
            get_string('usersdeleted', 'tool_uploadusercli') . ": $deleted",
            "",
            get_string('errors', 'tool_uploadusercli') . ": $errors",
            get_string('total', 'tool_uploadusercli') . ": $total",
        );

        if ($this->outputmode == self::OUTPUT_PLAIN) {
            foreach ($message as $msg) {
                $this->buffer->output($msg);
            }
        }     
    }
}
