/if[ \t]*\(type==EV_KEY\)/ {
    in_key = 1
    print "                    if (type==EV_KEY) {"
    print "                        if (value>1) continue; // ignore repeats"
    print "                        pressed = value;"
    print "                        if (code==304)      { btn = BTN_A;      id = BTN_ID_A; }"
    print "                        else if (code==305) { btn = BTN_B;      id = BTN_ID_B; }"
    print "                        else if (code==306) { btn = BTN_X;      id = BTN_ID_X; }"
    print "                        else if (code==307) { btn = BTN_Y;      id = BTN_ID_Y; }"
    print "                        else if (code==308) { btn = BTN_L1;     id = BTN_ID_L1; }"
    print "                        else if (code==309) { btn = BTN_R1;     id = BTN_ID_R1; }"
    print "                        else if (code==314) { btn = BTN_L2;     id = BTN_ID_L2; }"
    print "                        else if (code==315) { btn = BTN_R2;     id = BTN_ID_R2; }"
    print "                        else if (code==310) { btn = BTN_START;  id = BTN_ID_START; }"
    print "                        else if (code==311) { btn = BTN_SELECT; id = BTN_ID_SELECT; }"
    print "                        else if (code==313) { btn = BTN_MENU;   id = BTN_ID_MENU; }"
    print "                        else if (code==116) { btn = BTN_POWER;  id = BTN_ID_POWER; }"
    print "                        else if (code==115) { btn = BTN_PLUS;   id = BTN_ID_PLUS; }"
    print "                        else if (code==114) { btn = BTN_MINUS;  id = BTN_ID_MINUS; }"
    print "                        else { btn = BTN_NONE; }"
    print "                    }"
    next
}
in_key && /else if[ \t]*\(type==EV_ABS\)/ {
    in_key = 0
    print
    next
}
in_key { next }
{ print }
