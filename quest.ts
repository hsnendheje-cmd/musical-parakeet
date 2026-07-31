// @ts-nocheck
declare const ptr: any;
declare const Interceptor: any;
declare const Module: any;
declare const Memory: any;
declare const NativeFunction: any;
declare const Script: any;

const QUEST_PLATFORM = 1;
const SYMBOLS_URL = "https://pastebin.com/raw/yWXMXiSH";

function parseUrl(url: string): {
  hostname: string;
  path: string;
  port: number;
} {
  const match = url.match(/^https?:\/\/([^/:]+)(?::(\d+))?(.*)$/);
  if (!match) {
    return { hostname: "", path: "/", port: 443 };
  }
  const hostname = match[1];
  const port = match[2]
    ? parseInt(match[2])
    : url.startsWith("https")
      ? 443 // made by byte
      : 80;
  const path = match[3] || "/";
  return { hostname, path, port };
}

function httpRequest(
  url: string,
  method: string,
  headers: any,
  body?: string, // made by byte
): Promise<{ status: number; data: string }> {
  return new Promise((resolve) => {
    try {
      const winhttp = Module.load("winhttp.dll");

      const WinHttpOpen = new NativeFunction(
        winhttp.getExportByName("WinHttpOpen"),
        "pointer",
        ["pointer", "uint32", "pointer", "pointer", "uint32"],
      );

      const WinHttpConnect = new NativeFunction(
        winhttp.getExportByName("WinHttpConnect"),
        "pointer",
        ["pointer", "pointer", "uint32", "uint32"],
      ); // made by byte

      const WinHttpOpenRequest = new NativeFunction(
        winhttp.getExportByName("WinHttpOpenRequest"),
        "pointer",
        [
          "pointer",
          "pointer",
          "pointer",
          "pointer",
          "pointer",
          "pointer",
          "uint32",
        ],
      );

      const WinHttpSendRequest = new NativeFunction(
        winhttp.getExportByName("WinHttpSendRequest"),
        "bool",
        [
          "pointer",
          "pointer", // made by byte
          "uint32",
          "pointer",
          "uint32",
          "uint32",
          "pointer",
        ],
      );

      const WinHttpReceiveResponse = new NativeFunction(
        winhttp.getExportByName("WinHttpReceiveResponse"),
        "bool",
        ["pointer", "pointer"],
      );

      const WinHttpQueryHeaders = new NativeFunction(
        winhttp.getExportByName("WinHttpQueryHeaders"), // made by byte
        "bool",
        ["pointer", "uint32", "pointer", "pointer", "pointer", "pointer"],
      );

      const WinHttpReadData = new NativeFunction( // made by byte
        winhttp.getExportByName("WinHttpReadData"),
        "bool",
        ["pointer", "pointer", "uint32", "pointer"],
      );

      const WinHttpCloseHandle = new NativeFunction(
        winhttp.getExportByName("WinHttpCloseHandle"), // made by byte
        "bool",
        ["pointer"],
      );

      const WinHttpSetOption = new NativeFunction(
        winhttp.getExportByName("WinHttpSetOption"),
        "bool",
        ["pointer", "uint32", "pointer", "uint32"],
      );

      const WinHttpSetTimeouts = new NativeFunction(
        winhttp.getExportByName("WinHttpSetTimeouts"),
        "bool",
        ["pointer", "int32", "int32", "int32", "int32"],
      );

      const GetLastError = new NativeFunction(
        Module.load("kernel32.dll").getExportByName("GetLastError"),
        "uint32",
        [],
      );

      const urlParts = parseUrl(url);
      const hostname = urlParts.hostname;
      const path = urlParts.path;
      const port = urlParts.port;

      const userAgent = Memory.allocUtf16String(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      );
      const hSession = WinHttpOpen(userAgent, 0, ptr(0), ptr(0), 0);

      if (hSession.isNull()) {
        resolve({
          status: 0,
          data: "WinHttpOpen failed (" + GetLastError() + ")",
        });
        return;
      }

      WinHttpSetTimeouts(hSession, 5000, 5000, 5000, 5000);

      const hostnameW = Memory.allocUtf16String(hostname);
      const hConnect = WinHttpConnect(hSession, hostnameW, port, 0);

      if (hConnect.isNull()) {
        WinHttpCloseHandle(hSession);
        resolve({ status: 0, data: "WinHttpConnect failed" });
        return;
      }

      const pathW = Memory.allocUtf16String(path);
      const methodW = Memory.allocUtf16String(method);
      const hRequest = WinHttpOpenRequest(
        hConnect,
        methodW,
        pathW,
        ptr(0),
        ptr(0),
        ptr(0),
        url.startsWith("https") ? 0x00800000 : 0,
      );

      if (hRequest.isNull()) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        resolve({ status: 0, data: "WinHttpOpenRequest failed" });
        return;
      }

      const flagsBuf = Memory.alloc(4);
      flagsBuf.writeU32(0x00000100 | 0x00000200 | 0x00001000 | 0x00002000);
      WinHttpSetOption(hRequest, 31, flagsBuf, 4);

      let headersStr = "";
      for (const key in headers) {
        headersStr += key + ": " + headers[key] + "\r\n";
      }
      const headersW = Memory.allocUtf16String(headersStr);

      const bodyPtr = body ? Memory.allocUtf8String(body) : ptr(0);
      const bodyLen = body ? body.length : 0;

      if (
        !WinHttpSendRequest(
          hRequest,
          headersW,
          -1,
          bodyPtr,
          bodyLen,
          bodyLen,
          ptr(0),
        )
      ) {
        const err = GetLastError();
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        resolve({ status: 0, data: "WinHttpSendRequest failed (" + err + ")" });
        return;
      }

      if (!WinHttpReceiveResponse(hRequest, ptr(0))) {
        const err = GetLastError();
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        resolve({
          status: 0,
          data: "WinHttpReceiveResponse failed (" + err + ")",
        });
        return;
      }

      const statusBuffer = Memory.alloc(4);
      const statusSize = Memory.alloc(4);
      statusSize.writeU32(4);

      WinHttpQueryHeaders(
        hRequest,
        0x20000013,
        ptr(0),
        statusBuffer,
        statusSize,
        ptr(0),
      );
      const statusCode = statusBuffer.readU32();

      const buffer = Memory.alloc(8192);
      const bytesRead = Memory.alloc(4);
      let responseData = "";

      while (WinHttpReadData(hRequest, buffer, 8192, bytesRead)) {
        const size = bytesRead.readU32();
        if (size === 0) break;
        responseData += buffer.readUtf8String(size);
      }

      WinHttpCloseHandle(hRequest);
      WinHttpCloseHandle(hConnect);
      WinHttpCloseHandle(hSession);

      resolve({ status: statusCode, data: responseData });
    } catch (e) {
      console.log("[-] HTTP request error: " + e);
      resolve({ status: 0, data: "Error: " + e });
    }
  });
}

async function loadQuestServers() {
  console.log("\n");
  console.log("[+] Unpatchable Quest Servers");
  console.log("[+] Made by w2g8 on discord...");

  const symResponse = await httpRequest(SYMBOLS_URL, "GET", {});
  if (symResponse.status === 200) {
    try {
      eval(symResponse.data);

      const mapping: any = {
        "il2cpp_init": "FhZZcRHpAAQ",
  "il2cpp_init_utf16": "FtkHxhuTnPN",
  "il2cpp_shutdown": "kcXpJpaRrKR",
  "il2cpp_set_config_dir": "iDp_suurWpA",
  "il2cpp_set_data_dir": "bXgWhJQXXkV",
  "il2cpp_set_temp_dir": "KagUUbHLwMc",
  "il2cpp_set_commandline_arguments": "RJAWjMxaIQr",
  "il2cpp_set_commandline_arguments_utf16": "_wr_fEVXLJx",
  "il2cpp_set_config_utf16": "_LeRRpNxQHx",
  "il2cpp_set_config": "yynicpzFOPK",
  "il2cpp_set_memory_callbacks": "AskXYuQRdZQ",
  "il2cpp_memory_pool_set_region_size": "JKxUTaXVBPr",
  "il2cpp_memory_pool_get_region_size": "bJcQXvJawRA",
  "il2cpp_get_corlib": "JHyvjxAJDDG",
  "il2cpp_add_internal_call": "FCmBFaPNFgb",
  "il2cpp_resolve_icall": "KNMwBkbMlKC",
  "il2cpp_alloc": "uvLgEKZvdUG",
  "il2cpp_free": "NXbTaGUkGvK",
  "il2cpp_array_class_get": "qyQnIaExHhH",
  "il2cpp_array_length": "vvbfVMnQdpt",
  "il2cpp_array_get_byte_length": "XXyjTLqWCkN",
  "il2cpp_array_new": "tLTNaRmXZNp",
  "il2cpp_array_new_specific": "IsCRRALuMA_",
  "il2cpp_array_new_full": "rcJkpfuczHC",
  "il2cpp_bounded_array_class_get": "aWDPaVmmWDk",
  "il2cpp_array_element_size": "FwhoblNVauG",
  "il2cpp_assembly_get_image": "SdwwJkbnUPY",
  "il2cpp_class_for_each": "vMUnsagkuBf",
  "il2cpp_class_enum_basetype": "bNTmbsusUjW",
  "il2cpp_class_is_inited": "rfypzAkhSdk",
  "il2cpp_class_is_generic": "moujphPjzRN",
  "il2cpp_class_is_inflated": "MBDQdmgxxFf",
  "il2cpp_class_is_assignable_from": "aFmRzwLWYhF",
  "il2cpp_class_is_subclass_of": "KHDpdtyQzcL",
  "il2cpp_class_has_parent": "RhIRjmvqUNS",
  "il2cpp_class_from_il2cpp_type": "mvUKhA_kyWT",
  "il2cpp_class_from_name": "_jNBjZZIrxW",
  "il2cpp_class_from_system_type": "PctoqUMRMtE",
  "il2cpp_class_get_element_class": "LREjRIUhsTH",
  "il2cpp_class_get_events": "JGKNCevSPDI",
  "il2cpp_class_get_fields": "NCRWyTpyxoZ",
  "il2cpp_class_get_nested_types": "BGKpCqfNuxn",
  "il2cpp_class_get_interfaces": "cmQKnLqUmhD",
  "il2cpp_class_get_properties": "RpUBlD_SjFn",
  "il2cpp_class_get_property_from_name": "EgBdHBupCcD",
  "il2cpp_class_get_field_from_name": "FHqmVNdBSnN",
  "il2cpp_class_get_methods": "NmSnSZrrKEw",
  "il2cpp_class_get_method_from_name": "UYzXjbpzJTH",
  "il2cpp_class_get_name": "yPvIWAJJLVf",
  "il2cpp_type_get_name_chunked": "NqlczextQQU",
  "il2cpp_class_get_namespace": "dyskjdjWjvB",
  "il2cpp_class_get_parent": "iLQh_fqInnj",
  "il2cpp_class_get_declaring_type": "BCtmYNkIRsu",
  "il2cpp_class_instance_size": "KNC_bHKGQOq",
  "il2cpp_class_num_fields": "safVUQAWBda",
  "il2cpp_class_is_valuetype": "VSxDLIyGevb",
  "il2cpp_class_value_size": "vVjsFfBeTWU",
  "il2cpp_class_is_blittable": "AgcWAIhTBfW",
  "il2cpp_class_get_flags": "fWOajgOrtSo",
  "il2cpp_class_is_abstract": "RIHokShdLVa",
  "il2cpp_class_is_interface": "hvNHkKazTHo",
  "il2cpp_class_array_element_size": "CfrzJOZGnjn",
  "il2cpp_class_from_type": "nynrUMbOLaw",
  "il2cpp_class_get_type": "lMZNaUeEgiT",
  "il2cpp_class_get_type_token": "gsTyQtqStUd",
  "il2cpp_class_has_attribute": "tSzdtDUZYKO",
  "il2cpp_class_has_references": "wcWA_JupHcb",
  "il2cpp_class_is_enum": "yDHTdJrdhmc",
  "il2cpp_class_get_image": "hSiQUqYWTpM",
  "il2cpp_class_get_assemblyname": "JalvBaIgPej",
  "il2cpp_class_get_rank": "HZ_fypltuTx",
  "il2cpp_class_get_data_size": "qrGfnNNHaAM",
  "il2cpp_class_get_static_field_data": "GUVHBHxhcMC",
  "il2cpp_stats_dump_to_file": "QDwvSLwQHJq",
  "il2cpp_stats_get_value": "mxLuVnFtVsn",
  "il2cpp_domain_get": "yNZapYMBJzq",
  "il2cpp_domain_assembly_open": "FDJnRtnPpKO",
  "il2cpp_domain_get_assemblies": "KkMDjphYpRN",
  "il2cpp_raise_exception": "enOYiqJkaXH",
  "il2cpp_exception_from_name_msg": "pCosrfnvLsR",
  "il2cpp_get_exception_argument_null": "FqRQyZoamLV",
  "il2cpp_format_exception": "tgkDbsShpdn",
  "il2cpp_format_stack_trace": "PozQGPVLfMG",
  "il2cpp_unhandled_exception": "wdmNrjvLrBa",
  "il2cpp_native_stack_trace": "jIWDoLiPsNt",
  "il2cpp_field_get_flags": "dVSeHimQInE",
  "il2cpp_field_get_from_reflection": "BVnfzMIZHWP",
  "il2cpp_field_get_name": "WtfyLCOasXX",
  "il2cpp_field_get_parent": "dSzdwleJNJJ",
  "il2cpp_field_get_object": "dckQjtOVsWJ",
  "il2cpp_field_get_offset": "qf_EnNiaYas",
  "il2cpp_field_get_type": "VhYfNKXIcuz",
  "il2cpp_field_get_value": "uHdRHvmRLUp",
  "il2cpp_field_get_value_object": "vITcNShefZN",
  "il2cpp_field_has_attribute": "eDEbsFoJepB",
  "il2cpp_field_set_value": "wHsOJxkBfTg",
  "il2cpp_field_static_get_value": "GoQ_xYlSiwg",
  "il2cpp_field_static_set_value": "blvDgJtjFMn",
  "il2cpp_field_set_value_object": "cXfgKSMDFxO",
  "il2cpp_field_is_literal": "JGcHoPAWMwu",
  "il2cpp_gc_collect": "REqRnPZjbcB",
  "il2cpp_gc_collect_a_little": "AMWTuZgrdow",
  "il2cpp_gc_start_incremental_collection": "gZAmSXEdPEk",
  "il2cpp_gc_disable": "BPUMw_qdLic",
  "il2cpp_gc_enable": "UCThYkpuQXO",
  "il2cpp_gc_is_disabled": "FYHTJuCCBmD",
  "il2cpp_gc_set_mode": "bRCSglkaxUk",
  "il2cpp_gc_get_max_time_slice_ns": "qwRrTbuYaDV",
  "il2cpp_gc_set_max_time_slice_ns": "AllSQQTlFwT",
  "il2cpp_gc_is_incremental": "fGazpgjxdhf",
  "il2cpp_gc_get_used_size": "OCbKYCaKqYJ",
  "il2cpp_gc_get_heap_size": "naDUPUfbmhP",
  "il2cpp_gc_wbarrier_set_field": "UNdYImYyFYx",
  "il2cpp_gc_has_strict_wbarriers": "XCuyZuThbjT",
  "il2cpp_gc_set_external_allocation_tracker": "ozIAtmBSToj",
  "il2cpp_gc_set_external_wbarrier_tracker": "ybwmcb_RyFD",
  "il2cpp_gc_foreach_heap": "tmJiH_hBoGN",
  "il2cpp_stop_gc_world": "WyleGsAAaYF",
  "il2cpp_start_gc_world": "uhmvQnDNboc",
  "il2cpp_gc_alloc_fixed": "_DpHutVuNMH",
  "il2cpp_gc_free_fixed": "SlaKylRr_Ck",
  "il2cpp_gchandle_new": "YBUTdGWTgae",
  "il2cpp_gchandle_new_weakref": "ttyEOYILlvp",
  "il2cpp_gchandle_get_target": "zgFyqeCgzIV",
  "il2cpp_gchandle_free": "RHexSQKFGSq",
  "il2cpp_gchandle_foreach_get_target": "vNczVFuLTYh",
  "il2cpp_object_header_size": "NMOmjPWcJNC",
  "il2cpp_array_object_header_size": "SRZbfmzTjrO",
  "il2cpp_offset_of_array_length_in_array_object_header": "gIZpPUSghmr",
  "il2cpp_offset_of_array_bounds_in_array_object_header": "ZiucVRPGtbc",
  "il2cpp_allocation_granularity": "frZdsyGuCQx",
  "il2cpp_unity_liveness_allocate_struct": "VbdPwOwhLDF",
  "il2cpp_unity_liveness_calculation_from_root": "EIFEjeyywFL",
  "il2cpp_unity_liveness_calculation_from_statics": "_BnPSdbMdMz",
  "il2cpp_unity_liveness_finalize": "unbCuWmqIra",
  "il2cpp_unity_liveness_free_struct": "hLMKvfxfFpw",
  "il2cpp_method_get_return_type": "XwOrJInbuvT",
  "il2cpp_method_get_declaring_type": "ZtkAfwZz_MR",
  "il2cpp_method_get_name": "RtMsjPjpjnR",
  "il2cpp_method_get_from_reflection": "ZMJBS_oYSmt",
  "il2cpp_method_get_object": "VVzsxoxKztw",
  "il2cpp_method_is_generic": "FsHHiAEYDrZ",
  "il2cpp_method_is_inflated": "jshxIqILEJy",
  "il2cpp_method_is_instance": "DvGgDNdTUox",
  "il2cpp_method_get_param_count": "txWcKpzsuZZ",
  "il2cpp_method_get_param": "zxNWTpFTvNz",
  "il2cpp_method_get_class": "HFblRg_gFlz",
  "il2cpp_method_has_attribute": "FKrSIPrBMjo",
  "il2cpp_method_get_flags": "LIitjqjutQC",
  "il2cpp_method_get_token": "bGOYAjxKaRq",
  "il2cpp_method_get_param_name": "dHMEQaaOsZq",
  "il2cpp_property_get_flags": "UgYdCegrmzx",
  "il2cpp_property_get_get_method": "UlovTNBeYqX",
  "il2cpp_property_get_set_method": "BjsIaliSDBv",
  "il2cpp_property_get_name": "vXjQxWeqIXO",
  "il2cpp_property_get_parent": "GAxaLfrGFny",
  "il2cpp_object_get_class": "CjtRXHRUz_s",
  "il2cpp_object_get_size": "RduAczAymUf",
  "il2cpp_object_get_virtual_method": "dVMepYEPHkb",
  "il2cpp_object_new": "NoifStVfaKs",
  "il2cpp_object_unbox": "TjiAZTOmJIP",
  "il2cpp_value_box": "mNWNifZKZNB",
  "il2cpp_monitor_enter": "xKOaWRxw_vl",
  "il2cpp_monitor_try_enter": "SXzBDLiwXVK",
  "il2cpp_monitor_exit": "mpnJmZvKtBY",
  "il2cpp_monitor_pulse": "QyWjqzEjcxc",
  "il2cpp_monitor_pulse_all": "qsYBUzygLwI",
  "il2cpp_monitor_wait": "RivE_TxgqiA",
  "il2cpp_monitor_try_wait": "WGDrpJdxkyQ",
  "il2cpp_runtime_invoke": "GPVeRJRg_uD",
  "il2cpp_runtime_invoke_convert_args": "kxVVisZAR__",
  "il2cpp_runtime_class_init": "GoPBarvHwWH",
  "il2cpp_runtime_object_init": "ZxLaxQjqYhl",
  "il2cpp_runtime_object_init_exception": "KcnYVVbxgPx",
  "il2cpp_runtime_unhandled_exception_policy_set": "pAzCkJqQaZY",
  "il2cpp_string_length": "dJkNwZhUMBS",
  "il2cpp_string_chars": "qyDYjmRawTg",
  "il2cpp_string_new": "S__oFtiJRt_",
  "il2cpp_string_new_len": "VoIyKIlQhIs",
  "il2cpp_string_new_utf16": "NueuntGAmwL",
  "il2cpp_string_new_wrapper": "iqFFdTvNrtK",
  "il2cpp_string_intern": "YiJmgPQqiWE",
  "il2cpp_string_is_interned": "eOoBHVWPdMt",
  "il2cpp_thread_current": "QukaIBuCvIU",
  "il2cpp_thread_attach": "wSRzRLyXeYv",
  "il2cpp_thread_detach": "MTZsIaBjQWs",
  "il2cpp_is_vm_thread": "UYwEunswNsV",
  "il2cpp_current_thread_walk_frame_stack": "VvBpcLmjUTP",
  "il2cpp_thread_walk_frame_stack": "gxMOlBEgHfo",
  "il2cpp_current_thread_get_top_frame": "tGpdDVKXVJK",
  "il2cpp_thread_get_top_frame": "fxVwzgkWHue",
  "il2cpp_current_thread_get_frame_at": "EGdUkpoVXJp",
  "il2cpp_thread_get_frame_at": "GmFpwDNddGv",
  "il2cpp_current_thread_get_stack_depth": "wUBsFKfzjHG",
  "il2cpp_thread_get_stack_depth": "fVPNIw_rcfJ",
  "il2cpp_override_stack_backtrace": "yMcDRkdoqUZ",
  "il2cpp_type_get_object": "eIojDVfwEkq",
  "il2cpp_type_get_type": "VXJqqSudCmy",
  "il2cpp_type_get_class_or_element_class": "AEQOUflllul",
  "il2cpp_type_get_name": "qcfBLBcTnqs",
  "il2cpp_type_is_byref": "AkuxfmeTtKS",
  "il2cpp_type_get_attrs": "bRJBjwsLnRd",
  "il2cpp_type_equals": "zMxsKFzzfjA",
  "il2cpp_type_get_assembly_qualified_name": "ndnHJJTWbqO",
  "il2cpp_type_get_reflection_name": "DbBhxJAVAcj",
  "il2cpp_type_is_static": "IstysBmqjaB",
  "il2cpp_type_is_pointer_type": "RbzWCnKgzIx",
  "il2cpp_image_get_assembly": "lffQMrofMpr",
  "il2cpp_image_get_name": "nYKUtWHnWIW",
  "il2cpp_image_get_filename": "vvjdFJbTo_X",
  "il2cpp_image_get_entry_point": "huPReRSVXAB",
  "il2cpp_image_get_class_count": "HxGMrjlAagi",
  "il2cpp_image_get_class": "aMiXyLUxjrz",
  "il2cpp_capture_memory_snapshot": "OJECwkzjUqm",
  "il2cpp_free_captured_memory_snapshot": "GsoWfTLFpgN",
  "il2cpp_set_find_plugin_callback": "YcNVMApngjT",
  "il2cpp_register_log_callback": "lPUyXsCvCfD",
  "il2cpp_debugger_set_agent_options": "bjnhbrHB_hE",
  "il2cpp_is_debugger_attached": "jQVkhbSlJaN",
  "il2cpp_register_debugger_agent_transport": "UymMJbsKqqG",
  "il2cpp_debug_foreach_method": "kiamFRCuIOA",
  "il2cpp_debug_get_method_info": "IKyHQAtAFNl",
  "il2cpp_unity_install_unitytls_interface": "HutjpZa_PBS",
  "il2cpp_custom_attrs_from_class": "zBWmGjAeZBe",
  "il2cpp_custom_attrs_from_method": "nsMSQcAIkKP",
  "il2cpp_custom_attrs_from_field": "XHNBqwnuyqq",
  "il2cpp_custom_attrs_get_attr": "GGNYKceqyGs",
  "il2cpp_custom_attrs_has_attr": "wPnDcwckvFn",
  "il2cpp_custom_attrs_construct": "nvEWIqRHdfh",
  "il2cpp_custom_attrs_free": "GRWiKIwUWlr",
  "il2cpp_class_set_userdata": "QmJhljemWFh",
  "il2cpp_class_get_userdata_offset": "PsayEHmFALu",
  "il2cpp_set_default_thread_affinity": "uiGBFEXAKVw",
  "il2cpp_unity_set_android_network_up_state_func": "kMWzscPYSkY"
};

      const symbols = (Il2Cpp as any).$config.exports;
      if (symbols) {
        for (const key in symbols) {
          if (mapping[key]) {
            symbols[mapping[key]] = symbols[key];
          }
        }
      }

  Il2Cpp.perform(() => {
    const findClass = (n: string) => {
      for (const a of Il2Cpp.domain.assemblies) {
        try {
          const k = a.image.tryClass(n);
          if (k) return k;
        } catch (_) {}
      }
      return null;
    };

    const AppUtils = findClass("AnimalCompany.AppUtils");
    if (!AppUtils) {
      console.log("[-] AppUtils not found");
      return;
    }

    let method: any = null;
    for (const m of AppUtils.methods) {
      if (
        /CalculatePhotonAppVersion/i.test(m.name) &&
        (m.returnType?.name || "") === "System.String"
      ) {
        method = m;
        break;
      }
    }

    if (!method) {
      console.log("[-] CalculatePhotonAppVersion not found");
      return;
    }

    Interceptor.attach(method.virtualAddress, {
      onEnter(args: any) {
        try {
          args[2] = ptr(QUEST_PLATFORM);
        } catch (_) {}
      },
    });
  });
    } catch (e) {
      console.log("[-] Error: " + e);
    }
  }
}

loadQuestServers();
