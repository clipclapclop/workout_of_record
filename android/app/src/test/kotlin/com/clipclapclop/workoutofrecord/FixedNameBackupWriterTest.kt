package com.clipclapclop.workoutofrecord

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.Assert.assertThrows

class FixedNameBackupWriterTest {
    private class FakeStore(
        initial: Map<String, ByteArray> = emptyMap(),
    ) : BackupDocumentStore {
        val files = initial.mapValuesTo(mutableMapOf()) { it.value.copyOf() }
        var corruptPendingWrite = false
        var corruptFinalDigest = false
        val failRenames = mutableSetOf<String>()
        var failDeleteName: String? = null

        override fun exists(name: String) = files.containsKey(name)

        override fun write(name: String, bytes: ByteArray) {
            files[name] = if (corruptPendingWrite && name == FixedNameBackupWriter.PENDING_NAME) {
                bytes.dropLast(1).toByteArray()
            } else {
                bytes.copyOf()
            }
        }

        override fun digest(name: String): BackupDocumentDigest {
            val bytes = files.getValue(name)
            if (corruptFinalDigest && name == FixedNameBackupWriter.FINAL_NAME) {
                return BackupDocumentDigest.fromBytes(bytes + 0)
            }
            return BackupDocumentDigest.fromBytes(bytes)
        }

        override fun rename(from: String, to: String): Boolean {
            if (from in failRenames) return false
            val bytes = files.remove(from) ?: return false
            files[to] = bytes
            return true
        }

        override fun delete(name: String): Boolean {
            if (failDeleteName == name) return false
            return files.remove(name) != null
        }
    }

    @Test
    fun `verified replacement keeps the exact final name and removes safety files`() {
        val old = byteArrayOf(1, 2, 3)
        val fresh = byteArrayOf(4, 5, 6, 7)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old))

        FixedNameBackupWriter(store).replace(fresh)

        assertArrayEquals(fresh, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PENDING_NAME))
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `staged verification failure leaves the existing backup untouched`() {
        val old = byteArrayOf(1, 2, 3)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old)).apply {
            corruptPendingWrite = true
        }

        assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertArrayEquals(old, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `unsupported initial rename leaves the existing backup untouched`() {
        val old = byteArrayOf(1, 2, 3)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old)).apply {
            failRenames.add(FixedNameBackupWriter.FINAL_NAME)
        }

        assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertArrayEquals(old, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `failed promotion rolls the previous backup back into place`() {
        val old = byteArrayOf(1, 2, 3)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old)).apply {
            failRenames.add(FixedNameBackupWriter.PENDING_NAME)
        }

        assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertArrayEquals(old, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `failed final verification rolls the previous backup back into place`() {
        val old = byteArrayOf(1, 2, 3)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old)).apply {
            corruptFinalDigest = true
        }

        assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertArrayEquals(old, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `failed safety-file cleanup rolls the previous backup back into place`() {
        val old = byteArrayOf(1, 2, 3)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old)).apply {
            failDeleteName = FixedNameBackupWriter.PREVIOUS_NAME
        }

        assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertArrayEquals(old, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `failed verification of a first backup leaves no invalid final file`() {
        val store = FakeStore().apply {
            corruptFinalDigest = true
        }

        assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertFalse(store.exists(FixedNameBackupWriter.FINAL_NAME))
        assertFalse(store.exists(FixedNameBackupWriter.PENDING_NAME))
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
    }

    @Test
    fun `interrupted replacement restores previous before accepting new work`() {
        val old = byteArrayOf(1, 2, 3)
        val uncertain = byteArrayOf(4, 5, 6)
        val store = FakeStore(
            mapOf(
                FixedNameBackupWriter.FINAL_NAME to uncertain,
                FixedNameBackupWriter.PREVIOUS_NAME to old,
                FixedNameBackupWriter.PENDING_NAME to byteArrayOf(7),
            ),
        )

        FixedNameBackupWriter(store).recoverInterruptedReplacement()

        assertArrayEquals(old, store.files[FixedNameBackupWriter.FINAL_NAME])
        assertFalse(store.exists(FixedNameBackupWriter.PREVIOUS_NAME))
        assertFalse(store.exists(FixedNameBackupWriter.PENDING_NAME))
    }

    @Test
    fun `rollback failure preserves the previous safety file`() {
        val old = byteArrayOf(1, 2, 3)
        val store = FakeStore(mapOf(FixedNameBackupWriter.FINAL_NAME to old)).apply {
            failRenames.add(FixedNameBackupWriter.PENDING_NAME)
            failRenames.add(FixedNameBackupWriter.PREVIOUS_NAME)
        }

        val error = assertThrows(BackupReplacementException::class.java) {
            FixedNameBackupWriter(store).replace(byteArrayOf(9, 8, 7))
        }

        assertTrue(error.message!!.contains(FixedNameBackupWriter.PREVIOUS_NAME))
        assertArrayEquals(old, store.files[FixedNameBackupWriter.PREVIOUS_NAME])
    }
}
