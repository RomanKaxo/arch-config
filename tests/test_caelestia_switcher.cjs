const {test} = require('node:test');
const assert = require('node:assert/strict');
const {readFileSync} = require('node:fs');
const {join} = require('node:path');
const vm = require('node:vm');
const logic = vm.createContext({});
vm.runInContext(readFileSync(join(__dirname, '../caelestia/config/.config/quickshell/caelestia/modules/switcher/Logic.js'), 'utf8'), logic);
const client = (address, workspace = '1', extra = {}) => ({address, workspace: {name: workspace}, pid: 7, class: 'kitty', mapped: true, hidden: false, focusHistoryID: 0, ...extra});
const config = {allWorkspaces: true, includeMinimized: true};
const addresses = (...args) => Array.from(logic.snapshot(...args), c => c.address);

test('resolve cards using IPC addresses, rejecting reused window identities', () => {
    const toplevel = {address: 'abc', lastIpcObject: client('0xabc')};
    const entry = logic.snapshot([toplevel.lastIpcObject], '0xabc', '1', config, [])[0];
    assert.equal(logic.matches(toplevel.lastIpcObject, entry), true);
    assert.equal(logic.matches({...toplevel.lastIpcObject, pid: 8}, entry), false);
    assert.equal(logic.matches(toplevel.lastIpcObject, undefined), false);
});

test('active first, then recent focus; cycling does not reorder the snapshot', () => {
    const windows = [client('a'), client('b'), client('c')];
    assert.deepEqual(addresses(windows, 'b', '1', config, ['a', 'c']), ['b', 'a', 'c']);
    assert.equal(logic.next(0, 1, 3), 1);
    assert.equal(logic.next(0, -1, 3), 2);
    assert.equal(logic.next(2, 1, 3), 0);
    assert.equal(logic.next(0, 1, 0), -1);
});

test('fallback MRU places never-focused windows last', () => {
    const windows = [client('a', '1', {focusHistoryID: -1}), client('b', '1', {focusHistoryID: 3}), client('c', '1', {focusHistoryID: 1})];
    assert.deepEqual(addresses(windows, '', '1', config, []), ['c', 'b', 'a']);
});

test('minimized windows recoverable, other hidden workspaces excluded', () => {
    const windows = [client('a'), client('b', 'special:minimized-b'), client('c', 'special:minimized'), client('d', 'special:scratch'), client('e', '1', {hidden: true})];
    assert.deepEqual(addresses(windows, 'a', '1', config, []), ['a', 'b', 'c']);
    assert.deepEqual(addresses(windows, 'a', '1', {...config, includeMinimized: false}, []), ['a']);
});

test('workspace filter includes pinned windows and the active special workspace', () => {
    const windows = [client('a'), client('b', '2'), client('c', '2', {pinned: true}), client('d', 'special:scratch')];
    assert.deepEqual(addresses(windows, 'a', '1', {...config, allWorkspaces: false}, []), ['a', 'c']);
    assert.deepEqual(addresses(windows, 'd', 'special:scratch', {...config, allWorkspaces: false}, []), ['d', 'c']);
});

test('exclude unmapped and unidentified windows; preserve process identity', () => {
    const windows = [client('a'), client('', '1'), client('b', '1', {mapped: false}), client('c', '1', {class: ''})];
    assert.deepEqual(addresses(windows, 'a', '1', config, []), ['a']);
    assert.equal(logic.snapshot(windows, 'a', '1', config, [])[0].pid, 7);
});
