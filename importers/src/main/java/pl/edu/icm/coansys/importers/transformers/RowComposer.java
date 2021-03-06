/*
 * (C) 2010-2012 ICM UW. All rights reserved.
 */
package pl.edu.icm.coansys.importers.transformers;

import pl.edu.icm.coansys.importers.constants.HBaseConstant;
import pl.edu.icm.coansys.importers.constants.ProtoConstants;
import pl.edu.icm.coansys.importers.models.DocumentDTO;

public class RowComposer {
    
    private RowComposer() {}

    public static String composeRow(DocumentDTO docDTO) {
        StringBuilder sb = new StringBuilder();
        sb.append(docDTO.getCollection());
        if (docDTO.getMediaTypes().size() > 0) {
            for (String t : docDTO.getMediaTypes()) {
                if (ProtoConstants.mediaTypePdf.equals(t)) {
                    sb.append(HBaseConstant.ROW_ID_SEPARATOR);
                    sb.append(HBaseConstant.ROW_ID_MEDIA_TYPE_PDF);
                }
            }
        }
        sb.append(HBaseConstant.ROW_ID_SEPARATOR);
        sb.append(docDTO.getKey());

        return sb.toString();
    }
}