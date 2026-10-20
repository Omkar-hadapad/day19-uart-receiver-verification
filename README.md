# Day 19 — UART Receiver Verification

<p align="center">
  <b>Digital VLSI • Verilog RTL • UART Protocol • Functional Verification • Cadence NCSim</b>
</p>

<p align="center">
  <code>Specification → RTL → Testbench → Simulation → Waveform Analysis → Synthesis → PPA Review</code>
</p>

<p align="center">
  <img alt="Project" src="https://img.shields.io/badge/Project-Day%2019-blue">
  <img alt="HDL" src="https://img.shields.io/badge/HDL-Verilog-8A2BE2">
  <img alt="Simulation" src="https://img.shields.io/badge/Simulation-Cadence%20NCSim-orange">
  <img alt="Verification" src="https://img.shields.io/badge/Verification-115%20Pass%20%7C%200%20Fail-brightgreen">
</p>

---

## 1. Project Information

| Parameter | Details |
|---|---|
| **Project** | Day 19 — UART Receiver Verification |
| **Author** | Omkar Kalmesh Hadapad |
| **Domain** | Digital VLSI / RTL Design / Functional Verification |
| **Design Type** | UART serial receiver |
| **HDL** | Verilog HDL |
| **Simulation Tool** | Cadence NCSim |
| **Testbench** | `day19_tb.v` |
| **Top Testbench Module** | `day19_tb` |
| **Verification Approach** | Component checks, complete-frame tests, and RTL-versus-structural comparison |
| **Waveform Database** | `waves.shm` |
| **Simulation Result** | 115 passes, 0 failures |
| **Project Status** | Simulation regression passed; further coverage and implementation checks remain useful |

> **Evidence note:** The simulation summary, area report, power report, and timing-path report were supplied as separate outputs. Area, power, and timing values below are reported synthesis-stage results; they are not post-route results.

---

## 2. Project Overview

A UART (Universal Asynchronous Receiver/Transmitter) receiver converts a serial input stream into parallel data. A common UART frame contains a start bit, data bits transmitted least-significant bit first, and a stop bit. The actual frame configuration must follow the design specification.

This project verifies the receiver's component-level behavior and complete-frame operation. The testbench checks the synchronizer, baud counter, bit counter, data register, receiver logic, FSM, reset behavior, framing-error detection, and structural-versus-RTL behavior.

The supplied NCSim transcript reports **115 passes and 0 failures**. The checks include multiple data patterns, back-to-back frames, invalid-stop handling, and final idle-state safety.

### UART frame concept

```text
Idle       Start        Data bits, LSB first          Stop
  1     |    0    |  d0 | d1 | d2 | ... | d7   |       1
        <----------- One received frame ------------>
```

This illustrates a common 8-data-bit UART frame. Confirm the implemented data width, baud timing, and any parity support against the RTL specification.

---

## 3. Objectives

1. Understand the UART receiver data path and control path.
2. Verify basic combinational logic blocks.
3. Check half-adder, full-adder, and incrementer functionality included in the testbench.
4. Verify the RX synchronizer, baud counter, bit counter, and data register.
5. Check receiver logic and FSM state transitions.
6. Verify reset behavior for structural, RTL, and top-level implementations.
7. Test complete UART frames and multiple received data patterns.
8. Check back-to-back frames and invalid-stop/framing-error behavior.
9. Compare structural and RTL implementations.
10. Inspect simulation waveforms and review synthesis-stage PPA reports.

---

## 4. Day 19 — Verification Results

### 1. Simulation summary

| Verification item | Reported result |
|---|---|
| Pass count | **115** |
| Fail count | **0** |
| Testbench result | **ALL TESTS PASSED** |
| Simulation termination | `$finish` at 6156 ns |
| Waveform database | `waves.shm` |

The simulation transcript reports successful completion. This is evidence for the checks exercised by the testbench; it is not proof of exhaustive or formal verification.

### 2. Tests covered in the transcript

| Test | Purpose | Reported result |
|---|---|---|
| Test 1 — Basic gates | AND, OR, NOT, XOR, NAND, NOR | Displayed checks pass |
| Test 2 — Half adder | Sum and carry | Displayed checks pass |
| Test 3 — Full adder | Sum and carry | Displayed checks pass |
| Test 4 — 4-bit incrementer | Incrementing and rollover | Displayed checks pass |
| Test 5 — RX synchronizer | Synchronizer delay and output levels | Displayed checks pass |
| Test 6 — Baud counter | Count, tick, and rollover | Displayed checks pass |
| Test 7 — Data register | Data loading | Displayed check passes |
| Test 8 — Bit counter | Count and last-bit indication | Displayed checks pass |
| Test 9 — RX logic | Busy, sampling, valid stop, and framing error | Displayed checks pass |
| Test 10 — FSM | Reset, start, data, and stop states | Displayed checks pass |
| Test 11 — Reset safety | Structural, RTL, and top-level reset behavior | Displayed checks pass |
| Test 12 — Complete UART frame | Reception of `A5` | Displayed checks pass |
| Test 13 — Multiple data patterns | `00`, `FF`, `55`, `AA`, `3C`, `C3` | Displayed checks pass |
| Test 14 — Back-to-back frames | Consecutive `3C` and `C3` frames | Displayed checks pass |
| Test 15 — Invalid stop | Framing-error detection | Displayed check passes |
| Test 16 — Structural versus RTL | Data, busy, valid, and error comparison | Displayed checks pass |
| Test 17 — Final idle safety | Busy, valid, and error return to idle values | Displayed checks pass |

*The table summarizes the checks visible in the supplied transcript. The pass/fail totals are the simulator's reported summary.*

### 3. Important verification observations

The transcript reports that:
- The receiver recovered `A5` correctly in the structural, RTL, and top-level checks.
- Multiple data patterns were received as expected.
- Back-to-back frame checks for `3C` and `C3` passed.
- An invalid stop bit produced the expected framing-error indication.
- Structural-versus-RTL comparisons passed for the listed data and status signals.
- Final idle-state checks showed `busy`, `valid`, and `error` at zero.

These results support the tested behaviors. Additional randomized testing, coverage measurement, and independent review of the reference model can improve confidence.

---

## 5. What Hardware Does This RTL Create?

A UART receiver commonly contains input synchronization, timing counters, a data register, and control logic.

```text
             Asynchronous serial RX
                       |
                       v
              +------------------+
              | RX Synchronizer  |
              +--------+---------+
                       |
                       v
              +------------------+
              | FSM / RX Control |
              +----+--------+----+
                   |        |
                   v        v
            +-----------+  +-----------+
            | Baud      |  | Bit       |
            | Counter   |  | Counter   |
            +-----+-----+  +-----+-----+
                  |              |
                  +------+-------+
                         |
                         v
                +------------------+
                | Data Register    |
                +--------+---------+
                         |
                         v
                 Parallel Data Output
```

This is a conceptual block diagram. Confirm actual module connections and signal names from the RTL and structural source files.

### Functional role of each block

| Block | Typical role |
|---|---|
| RX synchronizer | Synchronizes the asynchronous RX input to the local clock domain |
| Baud counter | Generates timing events for sampling |
| Bit counter | Tracks the number or index of received data bits |
| Data register | Stores the received parallel data |
| FSM | Controls idle, start, data, and stop processing |
| RX logic | Coordinates sampling, busy/valid status, and framing-error behavior |

---

## 6. Simulation and Waveform Analysis

### 1. Waveform database

The supplied NCSim session opens the SHM database and probes testbench signals:

```tcl
database -open waves -into waves.shm -default
probe -create -shm day19_tb.clk day19_tb.reset
run
```

The actual transcript probes additional signals, including counters, FSM state, data outputs, status outputs, and pass/fail counters.

### 2. Signals to inspect

| Signal | What to verify |
|---|---|
| `clk` | Clock edges and sampling relationship |
| `reset` | Reset assertion, release, and recovery |
| `rx` / `sync_rx` | Serial input and synchronized input |
| `baud_count` / `baud_tick` | Sampling interval and counter rollover |
| `bit_count` / `bit_last` | Data-bit progression and final-bit indication |
| `fsm_state` / `fsm_next_state` | State progression through the frame |
| `data_reg_out` | Captured parallel data |
| `top_data` / `rtl_data` / `struct_data` | Output agreement across implementations |
| `top_busy` / `rtl_busy` / `struct_busy` | Busy behavior |
| `top_valid` / `rtl_valid` / `struct_valid` | Data-valid behavior |
| `top_error` / `rtl_error` / `struct_error` | Framing-error behavior |

### 3. Waveform review procedure

1. Open `waves.shm` in the waveform viewer supported by your Cadence installation.
2. Inspect start-bit detection and the first data-bit sample.
3. Check baud-counter rollover and sampling events.
4. Confirm that the bit counter advances at the intended events.
5. Compare the received data with the expected value at frame completion.
6. Inspect valid, busy, and framing-error timing.
7. Compare structural and RTL signals at the same simulation timestamps.

A passing test does not remove the value of waveform inspection, especially around reset, sampling boundaries, and back-to-back frames.

---

## 7. Synthesis and PPA Analysis

The supplied Genus reports identify `uart_receiver_top` as the top module and use the `tsmc18` library.

### 1. Reported results

| Metric | Reported result |
|---|---:|
| Mapped standard-cell instances | 91 |
| Total cell area | 2355.091 area units |
| Estimated total power | 214.529 µW |
| Sequential-cell area | 1496.880 area units (63.6%) |
| Combinational logic area | 831.600 area units (35.3%) |
| Inverter area | 26.611 area units (1.1%) |
| Reported setup slack | +6542 ps for one path |
| Clock period in the displayed timing path | 10 ns |
| Physical implementation stage | Synthesis-stage reports supplied |

> **Area-unit note:** The area report does not explicitly state the unit. Do not label the value as µm² unless the library/report configuration confirms that unit.

### 2. Area observations

The mapped-cell report contains 91 instances. The largest listed cell-area contributors include `DFFHQX1` and `SDFFTRX1`, so sequential-cell implementation is a significant area contributor.

This alone does not establish that any register is redundant. Review the RTL requirements, reset behavior, and synthesis mapping before changing register structures.

### 3. Power observations

| Category | Total power | Share |
|---|---:|---:|
| Register | 176.388 µW | 82.22% |
| Logic | 19.4552 µW | 9.07% |
| Clock | 18.6857 µW | 8.71% |
| **Total** | **214.529 µW** | **100%** |

The reported register category dominates the power estimate. The result depends on the power-analysis conditions and activity represented by the supplied frame (`/stim#0/frame#0`). Confirm the clock frequency and activity annotation before treating this as representative operating power.

### 4. Timing observations

The supplied timing path is reported as **MET**, with approximately **+6.542 ns setup slack**. It starts at `UART_RX/FSM/state_reg[1]` and ends at `UART_RX/safe_data_reg[7]`.

The displayed path includes logic associated with the baud counter and RX logic. This result applies to the displayed path only; the full timing summary is needed to establish whether all setup and hold paths meet constraints.

### 5. PPA limitations

The supplied reports do not establish:
- Post-route timing closure.
- Final routed area or signal-metal area.
- Post-route power including extracted parasitics.
- Timing status for every path.

Use the same constraints, library, operating conditions, and activity assumptions when comparing future synthesis runs.

---

## 8. Recommended Repository Structure

```text
day19-uart-receiver/
├── README.md
├── rtl/
│   ├── uart_receiver_top.v
│   ├── uart_rx_fsm.v
│   ├── uart_rx_baud_counter.v
│   ├── uart_rx_bit_counter.v
│   ├── uart_rx_data_register.v
│   ├── uart_rx_logic.v
│   └── uart_rx_synchronizer.v
├── structural/
│   └── uart_receiver_structural.v
├── tb/
│   └── day19_tb.v
├── sim/
│   ├── simulation.log
│   └── waveform/
├── reports/
│   ├── verification_summary.txt
│   ├── area.rpt
│   ├── power.rpt
│   └── timing.rpt
├── images/
│   └── uart_receiver_waveform.png
└── docs/
    └── Day19_UART_Receiver_Report.pdf
```

> This is a suggested layout. Keep only files that actually exist and use the exact names from your repository. Avoid committing generated simulation databases or proprietary technology-library files unless their licenses permit it.

---

## 9. Industry Relevance

UART receivers are used in embedded systems, microcontroller interfaces, debug ports, and serial communication subsystems.

This project demonstrates practice with:
- Synthesizable Verilog RTL.
- FSM-based control design.
- Counter-based sampling timing.
- Self-checking testbench development.
- Functional simulation and waveform review.
- RTL-versus-structural comparison.
- Synthesis area, power, and timing report interpretation.

---

## 10. Interview Questions

1. What is UART, and why is it asynchronous?
2. What is the purpose of the start bit and stop bit?
3. Why is UART data commonly transmitted least-significant bit first?
4. Why should an asynchronous RX input be synchronized?
5. What is the role of a baud counter?
6. What is the difference between a baud counter and a bit counter?
7. How does the FSM control data reception?
8. What is a framing error, and how can it be detected?
9. What is the difference between `busy` and `valid`?
10. How does a self-checking testbench determine whether received data is correct?
11. Why is a passing simulation not equivalent to formal verification?
12. What does positive setup slack indicate?
13. Why does synthesis-stage power differ from post-route power?
14. Why can sequential cells dominate area and power in a small digital design?
15. What evidence is needed before claiming post-route timing closure?

---

## 11. Project Status

| Stage | Status |
|---|---|
| Basic logic and arithmetic checks | Passed in supplied transcript |
| RX synchronizer and counter checks | Passed in supplied transcript |
| FSM and RX logic checks | Passed in supplied transcript |
| Reset safety | Passed in supplied transcript |
| Complete-frame reception | Passed for the tested `A5` frame |
| Multiple data patterns | Passed for the listed patterns |
| Back-to-back frames | Passed for the listed patterns |
| Invalid-stop/framing-error check | Passed in supplied transcript |
| Structural-versus-RTL checks | Passed for the listed comparisons |
| Functional regression | **115 passes, 0 failures reported** |
| Synthesis area and power review | Reports supplied; synthesis-stage results |
| Full timing closure | Not established by the single displayed path |
| Post-route PPA | Not established |

---

## 12. Final Verification Summary

| Parameter | Result |
|---|---|
| Testbench | `day19_tb` |
| Simulator | Cadence NCSim |
| Waveform database | `waves.shm` |
| Pass count | 115 |
| Fail count | 0 |
| Simulation status | **ALL TESTS PASSED** |
| Mapped-cell count | 91 |
| Cell area | 2355.091 area units |
| Estimated power | 214.529 µW |
| Displayed setup slack | +6.542 ns |

**Conclusion:** The supplied Day 19 simulation reports 115 passes and zero failures across the listed tests. The accompanying Genus reports provide a synthesis-stage baseline for area, power, and one setup path. Full timing closure and post-route PPA remain unverified by the supplied evidence.

---

## 13. Next Steps

1. Preserve the final simulation transcript and testbench.
2. Save representative waveforms for frame reception, back-to-back frames, reset, and framing-error detection.
3. Review the full setup and hold timing summaries.
4. Confirm the area unit and power-analysis activity assumptions.
5. Run physical implementation and post-route analysis if the flow and technology files are available.
6. Update this README only when new results are generated and reviewed.

---

## 14. Author

**Omkar Kalmesh Hadapad**  
Electronics and Communication Engineering  
Digital VLSI • Verilog RTL • Functional Verification

---

**Day 19 — UART Receiver Verification**
'''
