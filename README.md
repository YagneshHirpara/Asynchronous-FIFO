# Asynchronous FIFO Design in Verilog

This repository features a fully functional **Asynchronous FIFO (First-In First-Out)** buffer implemented using **Verilog HDL**. The design includes independent read and write clock domains and uses **Gray code synchronization** for safe pointer transfers. A comprehensive testbench is included to verify data integrity, synchronization, overflow/underflow behavior, and full/empty flag logic.

---

## 📌 Key Features

- Independent **read and write clocks**
- **Gray-coded pointers** for domain crossing
- Safe **dual flip-flop synchronizers**
- Full and Empty flag generation
- Parameterized `WIDTH` and `DEPTH`
- Verilog-compatible (IEEE 1364)

---

## 📘 Design Explanation

### 🧠 What Is an Asynchronous FIFO?

An Asynchronous FIFO allows data transfer between two different clock domains — typically used in SoCs and real-world digital systems where modules operate at independent frequencies. 

### 🏗️ Internal Architecture

1. **Memory Array**: Stores the actual data.
2. **Write and Read Pointers**:
   - Maintained in **binary** for addressing.
   - Converted to **Gray code** for cross-domain synchronization.
3. **Pointer Synchronizers**:
   - Two-stage flip-flop synchronizers prevent metastability.
   - `wq2_rptr`: read pointer synced into write clock domain.
   - `rq2_wptr`: write pointer synced into read clock domain.
4. **Control Logic**:
   - `FULL` asserted when write pointer is about to overlap unsynchronized read pointer.
   - `EMPTY` asserted when synchronized write and read pointers match.

### 🔐 Data Integrity

All write and read operations are gated based on FIFO full or empty conditions respectively to avoid corruption or invalid accesses.

---

## 📂 File Structure

```text
├── Async_FIFO.v        # Asynchronous FIFO design
├── tb_async_fifo.v     # Testbench with various test cases
