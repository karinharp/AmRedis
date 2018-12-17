#!/usr/bin/php
<?php
echo base64_encode(gzencode(file_get_contents('php://stdin')));
