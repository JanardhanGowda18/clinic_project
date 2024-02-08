// import 'package:flutter/material.dart';
//
// class _PatientDataSource extends DataTableSource {
//   final List<Map<String, dynamic>> _data;
//
//   _PatientDataSource(this._data);
//
//   @override
//   DataRow getRow(int index) {
//     final patient = _data[index];
//     return DataRow(cells: [
//       DataCell(Text(patient['pid']?.toString() ?? '')),
//       DataCell(Text(patient['name'] ?? '')),
//       DataCell(Text(patient['disease'] ?? '')),
//       DataCell(ElevatedButton(
//         onPressed: () {
//           _showDetailsModal(patient);
//         },
//         child: Text('View'),
//       )),
//     ]);
//   }
//
//   @override
//   bool get isRowCountApproximate => false;
//
//   @override
//   int get rowCount => _data.length;
//
//   @override
//   int get selectedRowCount => 0;
// }
