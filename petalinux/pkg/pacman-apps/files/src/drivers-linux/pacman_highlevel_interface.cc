#include <unistd.h>
#include <string>
#include <vector>
#include <map>
#include <cstdio>
#include <utility>
#include <cstddef>
#include <sstream>
#include <algorithm>
#include <charconv>
#include <iomanip>

#include "addr_conf.hh"
#include "pacman.hh"
#include "pacman_i2c.hh"

using std::string;
using std::vector;
using std::pair;
using std::map;

using kv_args_t = vector<pair<string,string>>;

struct pacman_command_t {
  string name;
  kv_args_t args;
};

static unsigned PACMAN_ID = 0;

// command string parser:
pacman_command_t parse_command_string(const string& cmd_str) {
  pacman_command_t cmd;
  std::istringstream iss(cmd_str);
  string token;

  bool first_token = true;
  while (iss >> token) {
    if (first_token) {
      cmd.name = token;
      first_token = false;
    } else {
      auto eq_pos = token.find('=');
      if (eq_pos != string::npos) {
	string key = token.substr(0, eq_pos);
	string val = token.substr(eq_pos + 1);
	cmd.args.push_back({key, val});
      } else {
	// treat as flag-like argument with empty value
	cmd.args.push_back({token, ""});
      }
    }
  }
  return cmd;
}

//returns true if the command lacks the provided token:
bool missing_arg(const pacman_command_t& cmd, const std::string& token) {
  for (const auto& kv : cmd.args) {
    if (kv.first == token) return false;
  }
  return true;
}

// return the string value of a token, or empty string if missing
std::string get_string(const pacman_command_t& cmd, const std::string& token) {
  for (const auto& kv : cmd.args) {
    if (kv.first == token) return kv.second;
  }
  return "";
}

#include <string>
#include <iostream>

bool get_unsigned(const pacman_command_t& cmd, const std::string& token, unsigned& out_val) {
    // Look up the token
    std::string s;
    for (const auto& kv : cmd.args) {
        if (kv.first == token) {
            s = kv.second;
            break;
        }
    }
    if (s.empty()) return false;

    // Parse using stoul with base 0 (auto-detects 0x for hex)
    try {
        out_val = std::stoul(s, nullptr, 0);
        return true;
    } catch (const std::invalid_argument&) {
        return false; // not a number
    } catch (const std::out_of_range&) {
        return false; // value too big
    }
}

inline std::string to_hex(unsigned val, unsigned width = 0, bool uppercase = true) {
    std::ostringstream oss;
    if (uppercase) oss << std::uppercase;
    oss << "0x";
    if (width > 0)
        oss << std::setw(width) << std::setfill('0');
    oss << std::hex << val;
    return oss.str();
}

// command handlers
string handle_ping(const pacman_command_t&)                  { return "pong"; }

string handle_report_version_details(const pacman_command_t&) { return "experimental"; }

string handle_set_pacman_id(const pacman_command_t& cmd) {
  unsigned id = 0;
  if (!get_unsigned(cmd,"id", id))
    return "ERROR: missing or invalid argument for id\r\n";
  PACMAN_ID = 0xFF&id;
  pacman_write(0x7FBC, PACMAN_ID);
  return "pacman id set to " + std::to_string(PACMAN_ID);
}
string handle_read_pacman_id(const pacman_command_t&){
  return std::to_string(PACMAN_ID);
}
string handle_set_vddd(const pacman_command_t& cmd) {
  return "not yet implemented";
}
string handle_set_vdda(const pacman_command_t& cmd) {
  return "not yet implemented";
}
string handle_enable_tile_power(const pacman_command_t&){
  unsigned tmp = 0;
  tmp = pacman_read(0xF010);
  tmp |= 0x00010000;
  pacman_write(0xF010, tmp);
  return "tile power enabled";
}
string handle_disable_tile_power(const pacman_command_t&){
  unsigned tmp = 0;
  tmp = pacman_read(0xF010);
  tmp &= 0xFFFEFFFF;
  pacman_write(0xF010, tmp);
  return "tile power disabled";
}
string handle_enable_tile(const pacman_command_t& cmd) {
  unsigned tmp, tile = 1;
  if ((!get_unsigned(cmd,"tile", tile))||(tile==0)||(tile>10))
      return "ERROR: missing or invalid argument for tile\n";
  tmp = pacman_read(0xF010);
  tmp |= (0x1<<(tile-1));
  pacman_write(0xF010, tmp);
  return "tile " + std::to_string(tile) + " is enabled.\n";
}
string handle_disable_tile(const pacman_command_t& cmd) {
  unsigned tmp, tile = 1;
  if ((!get_unsigned(cmd,"tile", tile))||(tile==0)||(tile>10))
      return "ERROR: missing or invalid argument for tile\n";
  tmp = pacman_read(0xF010);
  tmp &= ~(0x1<<(tile-1));
  pacman_write(0xF010, tmp);
  return "tile " + std::to_string(tile) + " is disabled.\n";
}

string handle_read_vddd(const pacman_command_t& cmd) {
  return "not yet implemented";
}

string handle_read_vdda(const pacman_command_t& cmd) {
  return "not yet implemented";
}

string handle_read_enables(const pacman_command_t&){
  return "not yet implemented";
}

string handle_send_full_reset(const pacman_command_t& cmd) {
  unsigned mask = 0;
  if (!get_unsigned(cmd, "mask", mask))
    return "ERROR: invalid or missing argument for mask\n";

  // update pulse duration for full reset (1023 cycles):
  pacman_write(0xE118, 0x03FF3FF5);
  pacman_write(0xE100, 0x00);
  usleep(10);

  // reset pulses triggered by poke C
  pacman_write(0xE0C0, mask);
  usleep(100);

  // set pulse duration back to default (internal reset, 8 cycles):
  pacman_write(0xE118, 0x03FF0085);
  pacman_write(0xE100, 0x00);
  usleep(10);

  return "full reset sent to " + to_hex(mask) + "\n";
}

string handle_send_internal_reset(const pacman_command_t& cmd) {
  unsigned mask = 0;
  if (!get_unsigned(cmd, "mask", mask))
    return "ERROR: invalid or missing argument for mask\n";
  // reset pulses triggered by poke C
  pacman_write(0xE0C0, mask);

  return "internal reset sent to " + to_hex(mask) + "\n";
}

string handle_send_sync_timestamp(const pacman_command_t& cmd) {
  unsigned mask = 0;
  if (!get_unsigned(cmd, "mask", mask))
    return "ERROR: invalid or missing argument for mask\n";

  // sync pulses are triggered by poke D
  pacman_write(0xE0D0, mask);
  return "sync timestamp sent to " + to_hex(mask) + "\n";
}

// command mux:
string dispatch_command(const pacman_command_t& cmd) {
    if (cmd.name == "ping")                       return handle_ping(cmd);
    else if (cmd.name == "report_version_details") return handle_report_version_details(cmd);
    else if (cmd.name == "set_pacman_id")         return handle_set_pacman_id(cmd);
    else if (cmd.name == "read_pacman_id")        return handle_read_pacman_id(cmd);
    else if (cmd.name == "set_vddd")              return handle_set_vddd(cmd);
    else if (cmd.name == "set_vdda")              return handle_set_vdda(cmd);
    else if (cmd.name == "enable_tile_power")     return handle_enable_tile_power(cmd);
    else if (cmd.name == "disable_tile_power")    return handle_disable_tile_power(cmd);
    else if (cmd.name == "enable_tile")           return handle_enable_tile(cmd);
    else if (cmd.name == "disable_tile")          return handle_disable_tile(cmd);
    else if (cmd.name == "read_vddd")             return handle_read_vddd(cmd);
    else if (cmd.name == "read_vdda")             return handle_read_vdda(cmd);
    else if (cmd.name == "read_enables")          return handle_read_enables(cmd);
    else if (cmd.name == "send_full_reset")       return handle_send_full_reset(cmd);
    else if (cmd.name == "send_internal_reset")   return handle_send_internal_reset(cmd);
    else if (cmd.name == "send_sync_timestamp")   return handle_send_sync_timestamp(cmd);
    else return "ERROR: unknown command";
}


// ----------------------------
// High-level PACMAN command interface
// ----------------------------
size_t pacman_highlevel_command(const char* req_str, size_t req_len,
                                char* rep_buf, size_t max_len) {
  printf("INFO:  Received command string: '%.*s'\n", (int)req_len, req_str);

  string cmd_str(req_str, req_len);
  pacman_command_t cmd = parse_command_string(cmd_str);

  printf("INFO: parsed command name: \"%s\"\n", cmd.name.c_str());
  for (auto& kv : cmd.args) {
    printf("INFO: arg: %s = %s\n", kv.first.c_str(), kv.second.c_str());
  }

  string rep_str = dispatch_command(cmd);

  int n = snprintf(rep_buf, max_len, "%s", rep_str.c_str());
  if (n < 0) return 0;
  if ((size_t)n > max_len) return max_len;
  return (size_t)n;
}

unsigned get_pacman_id(){
  return PACMAN_ID;
}
